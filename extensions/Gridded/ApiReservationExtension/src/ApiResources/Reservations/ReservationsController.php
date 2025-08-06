<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Admin\Models\Reservations_model; // <--- Importante
use Carbon\Carbon;
use Igniter\Api\Classes\ApiController; // <--- Cambia la clase base
use Igniter\Flame\Exception\ApplicationException;
use Igniter\Local\Facades\Location;
use Igniter\Reservation\Models\Table;

class ReservationsController extends ApiController // <--- Cambia la clase base
{
    // Sobrescribimos la acción 'store' (crear)
    public function store()
    {
        $data = request()->all();

        // 1. VALIDACIÓN (usando el validador simple por ahora)
        $rules = [
            'location_id'  => ['required', 'integer', 'exists:locations,location_id'],
            'guest_num'    => ['required', 'integer', 'min:1'],
            'first_name'   => ['required', 'string', 'min:2'],
            'last_name'    => ['required', 'string', 'min:2'],
            'email'        => ['required', 'email'],
            'telephone'    => ['required', 'string'],
            'reserve_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:today'],
            'reserve_time' => ['required', 'date_format:H:i'],
        ];

        $validator = validator($data, $rules);
        if ($validator->fails()) {
            return $this->response()->error($validator->errors()->first(), 422);
        }

        // --- INICIO DE TU LÓGICA MANUAL Y ROBUSTA ---
        $locationId = $data['location_id'];
        $guestNum = $data['guest_num'];

        $location = Location::getById($locationId);
        $locationTimezone = $location->timezone ?? config('app.timezone');
        $reservationDateTime = Carbon::parse($data['reserve_date'].' '.$data['reserve_time'], $locationTimezone);

        $workingSchedule = resolve('working_schedule', ['location' => $locationId]);
        if (!$workingSchedule->isOpen($reservationDateTime)) {
            throw new ApplicationException('El restaurante está cerrado a la hora y fecha seleccionadas.');
        }

        $stayTime = $location->getOption('reservation_stay_time', 90);
        $reservationEndDateTime = $reservationDateTime->copy()->addMinutes($stayTime);
        $confirmedStatusId = setting('confirmed_reservation_status');

        $bookedTableIds = Reservations_model::query()
            ->where('location_id', $locationId)
            ->where('status_id', $confirmedStatusId)
            ->where(function ($query) use ($reservationDateTime, $reservationEndDateTime) {
                $query->where('reservation_datetime', '<', $reservationEndDateTime)
                      ->whereRaw('ADDTIME(reservation_datetime, SEC_TO_TIME(duration * 60)) > ?', [$reservationDateTime]);
            })
            ->pluck('table_id')->filter()->unique();

        $availableTable = Table::query()
            ->where('is_enabled', true)
            ->where('location_id', $locationId)
            ->where('min_capacity', '<=', $guestNum)
            ->where('max_capacity', '>=', $guestNum)
            ->whereNotIn('table_id', $bookedTableIds)
            ->first();

        if (!$availableTable) {
            throw new ApplicationException('No hay mesas disponibles para los criterios seleccionados.');
        }

        $reservation = new Reservations_model();
        $reservation->fill($data);
        $reservation->table_id = $availableTable->table_id;
        $reservation->duration = $stayTime;
        $reservation->reservation_datetime = $reservationDateTime;
        $reservation->status_id = $confirmedStatusId;
        $reservation->save();
        // --- FIN DE TU LÓGICA ---

        // Devolvemos la respuesta usando el formato de la API
        return $this->response()->created($reservation);
    }
}