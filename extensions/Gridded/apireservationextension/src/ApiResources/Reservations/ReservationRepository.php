<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Igniter\Api\Classes\AbstractRepository;
use Igniter\Reservation\Models\Reservation;

class ReservationRepository extends AbstractRepository
{
    protected ?string $modelClass = Reservation::class;
}