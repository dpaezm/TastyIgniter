<?php

namespace Gridded\ApiReservationExtension;

use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationsController;
use Igniter\System\Classes\BaseExtension;

class Extension extends BaseExtension
{
    public function registerApiResources(): array
    {
        return [
            'custom-reservations' => [
                'name'        => 'Custom Reservations',           // ✔ obligatorio
                'description' => 'Crear reservas vía API',        // opcional
                'controller'  => ReservationsController::class,   // ✔ obligatorio
                'actions'     => ['store'],                       // usa “actions”, no “only”
            ],
        ];
    }
}