<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Carbon\Carbon;
use Igniter\Api\Classes\AbstractRepository;
use Igniter\Flame\Exception\ApplicationException;
use Igniter\Local\Facades\Location;
use Igniter\Reservation\Models\Reservation;
use Igniter\Reservation\Models\Table;

class ReservationRepository extends AbstractRepository
{
    protected ?string $modelClass = Reservation::class;

    /**
     * Crea una nueva reserva con validación completa.
     * Este método es llamado por el RestController en una petición POST.
     */
    public function create(array $data): Reservation
    {
        $locationId = $data['location_id'];
        $guestNum = $data['guest_num'];

        // 1. MANEJO DE ZONA HORARIA
        $location = Location::getById($locationId);
        if (!$location) {
            throw new ApplicationException('Location not found.');
        }
        $locationTimezone = $location->timezone ?? config('app.timezone');
        $reservationDateTime = Carbon::parse($data['reserve_date'].' '.$data['reserve_time'], $locationTimezone);

        // 2. COMPROBAR HORARIO DE APERTURA
        $workingSchedule = resolve('working_schedule', ['location' => $locationId]);
        if (!$workingSchedule->isOpen($reservationDateTime)) {
            throw new ApplicationException('El restaurante está cerrado a la hora y fecha seleccionadas.');
        }

        // 3. ENCONTRAR MESA DISPONIBLE
        $stayTime = $location->getOption('reservation_stay_time', 90);
        $reservationEndDateTime = $reservationDateTime->copy()->addMinutes($stayTime);
        $confirmedStatusId = setting('confirmed_reservation_status');

        if (!$confirmedStatusId) {
            throw new ApplicationException('El estado de reserva confirmada no está configurado en el sistema.');
        }

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
            ->where('location_id', $locationId)
            ->where('min_capacity', '<=', $guestNum)
            ->where('max_capacity', '>=', $guestNum)
            ->whereNotIn('table_id', $bookedTableIds)
            ->orderBy('priority', 'desc')
            ->orderBy('max_capacity', 'asc')
            ->first();

        // 4. SI NO HAY MESA, LANZAR ERROR
        if (!$availableTable) {
            throw new ApplicationException('No hay mesas disponibles para los criterios seleccionados.');
        }

        // 5. CREAR Y GUARDAR LA RESERVA
        $reservation = new Reservation();
        $reservation->fill($data);
        $reservation->table_id = $availableTable->table_id;
        $reservation->duration = $stayTime;
        $reservation->reservation_datetime = $reservationDateTime;
        $reservation->status_id = $confirmedStatusId;
        
        // Asignar el cliente autenticado a la reserva
        if ($customer = auth()->user()) {
            $reservation->customer_id = $customer->getKey();
        }
        
        $reservation->save();

        return $reservation;
    }
}