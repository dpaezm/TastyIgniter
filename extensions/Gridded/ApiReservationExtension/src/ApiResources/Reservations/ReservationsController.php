<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use League\Fractal\TransformerAbstract;
use Igniter\Reservation\Models\Reservation;

class ReservationTransformer extends TransformerAbstract
{
    public function transform(Reservation $reservation): array
    {
        return $reservation->toArray();
    }
}