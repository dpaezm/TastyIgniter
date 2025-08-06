<?php

namespace Gridded\ApiReservationExtension\Http\Controllers;

use Carbon\Carbon;
use Igniter\Flame\Exception\ApplicationException;
use Igniter\Local\Facades\Location;
use Igniter\Reservation\Models\Reservation;
use Igniter\Reservation\Models\Table;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Validator;

class ApiReservationController extends Controller
{
    public function store(Request $request)
    {
        // 1. VALIDACIÓN DE ENTRADA
        $rules = [
            'location_id'  => ['required', 'integer', 'exists:locations,location_id'],
            'guest_num'    => ['required', 'integer', 'min:1'],
            'first_name'   => ['required', 'string', 'min:2'],
            'last_name'    => ['required', 'string', 'min:2'],
            'email'        => ['required', 'email'],
            'telephone'    => ['required', 'string'],
            'reserve_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:today'],
            'reserve_time' => ['required', 'date_format:H:i'],
            'comment'      => ['nullable', 'string'],
        ];

        $data = Validator::make($request->all(), $rules)->validate();

        $locationId = $data['location_id'];
        $guestNum = $data['guest_num'];

        // 2. MANEJO DE ZONA HORARIA (CRÍTICO)
        $location = Location::getById($locationId);
        if (!$location) {
            throw new ApplicationException('Location not found.');
        }
        $locationTimezone = $location->timezone ?? config('app.timezone');
        $reservationDateTime = Carbon::parse($data['reserve_date'].' '.$data['reserve_time'], $locationTimezone);

        // 3. COMPROBAR HORARIO DE APERTURA (MANUAL)
        $workingSchedule = resolve('working_schedule', ['location' => $locationId]);
        if (!$workingSchedule->isOpen($reservationDateTime)) {
            throw new ApplicationException('El restaurante está cerrado a la hora y fecha seleccionadas.');
        }

        // 4. ENCONTRAR MESA DISPONIBLE (MANUAL)
        $stayTime = $location->getOption('reservation_stay_time', 90);
        $reservationEndDateTime = $reservationDateTime->copy()->addMinutes($stayTime);
        $confirmedStatusId = setting('confirmed_reservation_status');

        $bookedTableIds = Reservation::query()
            ->where('location_id', $locationId)
            ->where('status_id', $confirmedStatusId)
            ->where(function ($query) use ($reservationDateTime, $reservationEndDateTime) {
                $query->where('reservation_datetime', '<', $reservationEndDateTime)
                      ->whereRaw('ADDTIME(reservation_datetime, SEC_TO_TIME(duration * 60)) > ?', [$reservationDateTime]);
            })
            ->pluck('table_id')->filter()->unique();

        $availableTable = Table::query()
            ->where('is_enabled', true)
            ->where('min_capacity', '<=', $guestNum)
            ->where('max_capacity', '>=', $guestNum)
            ->whereNotIn('table_id', $bookedTableIds)
            ->orderBy('priority', 'desc')
            ->orderBy('max_capacity', 'asc')
            ->first();

        // 5. SI NO HAY MESA, LANZAR ERROR
        if (!$availableTable) {
            throw new ApplicationException('No hay mesas disponibles para los criterios seleccionados.');
        }

        // 6. CREAR Y GUARDAR LA RESERVA (MANUAL)
        $reservation = new Reservation();
        $reservation->fill($data); // Rellena con los datos originales validados
        $reservation->table_id = $availableTable->table_id;
        $reservation->duration = $stayTime;
        $reservation->reservation_datetime = $reservationDateTime; // Guarda el objeto Carbon
        $reservation->status_id = $confirmedStatusId; // Asigna el estado directamente
        $reservation->save();

        // 7. DEVOLVER RESPUESTA DE ÉXITO
        return response()->json([
            'success'     => true,
            'message'     => 'Reserva creada y confirmada con éxito.',
            'reservation' => $reservation->fresh(),
        ], 201);
    }
}