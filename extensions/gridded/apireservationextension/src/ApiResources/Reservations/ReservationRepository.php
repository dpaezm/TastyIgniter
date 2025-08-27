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

        // --- LÓGICA DE DISPONIBILIDAD MEJORADA (CONSULTA DIRECTA A BD) ---
        $startTime = $reservationDateTime->copy();
        $endTime = $reservationDateTime->copy()->addMinutes($stayTime);

        $bookedTableIds = Reservation::query()
            ->where('location_id', $locationId)
            ->where('status_id', $confirmedStatusId)
            ->whereDate('reserve_date', $startTime->toDateString())
            ->where(function ($query) use ($startTime, $endTime, $stayTime) {
                $query->whereTime('reserve_time', '<', $endTime->format('H:i:s'))
                      ->whereRaw('ADDTIME(reserve_time, SEC_TO_TIME(duration * 60)) > ?', [$startTime->format('H:i:s')]);
            })
            ->pluck('table_id')
            ->filter()
            ->unique();

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
        $reservation->duration = $stayTime; // Guardamos la duración
        $reservation->status_id = $confirmedStatusId;
        if ($customer = auth()->user()) {
            $reservation->customer_id = $customer->getKey();
        }
        $reservation->save();

        return $reservation;
    }
}