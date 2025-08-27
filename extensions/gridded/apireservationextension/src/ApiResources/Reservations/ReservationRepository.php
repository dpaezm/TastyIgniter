<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Carbon\Carbon;
use Igniter\Api\Classes\AbstractRepository;
use Igniter\Flame\Database\Model;
use Igniter\Flame\Exception\ApplicationException;
use Igniter\Reservation\Models\Reservation;
use Igniter\Reservation\Models\Table;
use Illuminate\Database\Eloquent\Model as EloquentModel;

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

        // CORRECCIÓN 1: Usar los nombres de columna correctos para la consulta
        $bookedTableIds = Reservation::query()
            ->where('location_id', $locationId)
            ->where('status_id', $confirmedStatusId)
            ->where(function ($query) use ($reservationDateTime, $reservationEndDateTime) {
                $query->where('reserve_date', $reservationDateTime->toDateString())
                      ->where(function($q) use ($reservationDateTime, $reservationEndDateTime) {
                          $q->whereBetween('reserve_time', [
                              $reservationDateTime->toTimeString(),
                              $reservationEndDateTime->toTimeString()
                          ])->orWhereBetween(DB::raw("ADDTIME(reserve_time, SEC_TO_TIME(duration * 60))"), [
                              $reservationDateTime->toTimeString(),
                              $reservationEndDateTime->toTimeString()
                          ]);
                      });
            })
            ->pluck('table_id')->filter()->unique();

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
        $reservation->duration = $stayTime;
        // CORRECCIÓN 2: No asignar a reservation_datetime directamente
        // El modelo lo calcula a partir de reserve_date y reserve_time, que ya están en $attributes
        $reservation->status_id = $confirmedStatusId;
        if ($customer = auth()->user()) {
            $reservation->customer_id = $customer->getKey();
        }
        $reservation->save();

        return $reservation;
    }
}