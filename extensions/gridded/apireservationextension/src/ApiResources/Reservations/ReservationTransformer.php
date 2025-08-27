<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Igniter\Api\Classes\TransformerAbstract;
use Igniter\Reservation\Models\Reservation;

class ReservationTransformer extends TransformerAbstract
{
    public function toArray(Reservation $reservation): array
    {
        return [
            'id' => $reservation->reservation_id,
            'location_id' => $reservation->location_id,
            'table_id' => $reservation->table_id,
            'table_name' => $reservation->table_name,
            'guest_num' => $reservation->guest_num,
            'customer_id' => $reservation->customer_id,
            'first_name' => $reservation->first_name,
            'last_name' => $reservation->last_name,
            'email' => $reservation->email,
            'telephone' => $reservation->telephone,
            'comment' => $reservation->comment,
            'reserve_datetime' => $reservation->reservation_datetime->toIso8601String(),
            'status_id' => $reservation->status_id,
            'status_name' => $reservation->status_name,
        ];
    }
}