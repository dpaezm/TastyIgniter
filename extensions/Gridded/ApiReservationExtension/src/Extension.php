<?php

namespace Gridded\ApiReservationExtension;

use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationsController;
use Igniter\System\Classes\BaseExtension;

class Extension extends BaseExtension
{
    public function registerApiResources()
    {
        return [
            'custom-reservations' => [
                'controller' => ReservationsController::class,
                'only' => ['store'],
            ],
        ];
    }
}