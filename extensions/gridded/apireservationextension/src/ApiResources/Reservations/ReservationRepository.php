<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Carbon\Carbon;
use Igniter\Api\Classes\AbstractRepository;
use Igniter\Flame\Database\Model;
use Igniter\Flame\Exception\ApplicationException;
use Igniter\Reservation\Models\Reservation;
use Igniter\Reservation\Models\Table;
use Illuminate\Database\Eloquent\Model as EloquentModel;
use Illuminate\Support\Facades\DB;

class ReservationRepository extends AbstractRepository
{
    protected ?string $modelClass = Reservation::class;

    public function create(Model|EloquentModel $model, array $attributes): Model|EloquentModel
    {
        $locationId = 1;
        $locationTimezone = 'Europe/Madrid';
        $stayTime = 90;

        if (empty($attributes['email'])) {
            $attributes['email'] = 'reservas@beautiful-app.gridded.agency';
        }

        $guestNum = $attributes['guest_num'];
        $reservationDateTime = Carbon::parse(
            $attributes['reserve_date'].' '.$attributes['reserve_time'],
            $locationTimezone
        );

        $confirmedStatusId = setting('confirmed_reservation_status');
        if (!$confirmedStatusId) {
            throw new ApplicationException('El estado de reserva confirmada no está configurado en el sistema.');
        }

        $reservationEndDateTime = $reservationDateTime->copy()->addMinutes($stayTime);

        // ==========================================================
        // ✅ INICIO: CORRECCIÓN DE LA CONSULTA DE DISPONIBILIDAD
        // ==========================================================
        $bookedTableIds = Reservation::query()
            ->where('location_id', $locationId)
            ->where('status_id', $confirmedStatusId)
            // Filtramos por las reservas que ocurren en la misma fecha
            ->whereDate('reserve_date', $reservationDateTime->toDateString())
            // Ahora comprobamos el solapamiento de tiempo
            ->where(function ($query) use ($reservationDateTime, $stayTime) {
                // Hora de inicio de la nueva reserva
                $startTime = $reservationDateTime->format('H:i:s');
                // Hora de fin de la nueva reserva
                $endTime = $reservationDateTime->copy()->addMinutes($stayTime)->format('H:i:s');

                // Lógica de solapamiento:
                // Una reserva existente (A) se solapa con la nueva (B) si:
                // HoraInicio(A) < HoraFin(B) Y HoraFin(A) > HoraInicio(B)
                $query->whereTime('reserve_time', '<', $endTime)
                      ->whereRaw('ADDTIME(reserve_time, SEC_TO_TIME(? * 60)) > ?', [$stayTime, $startTime]);
            })
            ->pluck('table_id')->filter()->unique();
        // ==========================================================
        // ✅ FIN: CORRECCIÓN DE LA CONSULTA DE DISPONIBILIDAD
        // ==========================================================

        $availableTable = Table::query()
            ->where('is_enabled', true)
            ->where('location_id', $locationId)
            ->where('min_capacity', '<=', $guestNum)
            ->where('max_capacity', '>=', $guestNum)
            ->whereNotIn('table_id', $bookedTableIds)
            ->orderBy('priority', 'desc')->orderBy('max_capacity', 'asc')
            ->first();

        if (!$availableTable) {
            throw new ApplicationException('No hay mesas disponibles para los criterios seleccionados.');
        }

        $reservation = new Reservation();
        $reservation->fill($attributes);
        $reservation->location_id = $locationId;
        $reservation->table_id = $availableTable->table_id;
        $reservation->duration = $stayTime; // El modelo sí tiene un campo `duration` para guardar
        $reservation->status_id = $confirmedStatusId;
        if ($customer = auth()->user()) {
            $reservation->customer_id = $customer->getKey();
        }
        $reservation->save();

        return $reservation;
    }
}