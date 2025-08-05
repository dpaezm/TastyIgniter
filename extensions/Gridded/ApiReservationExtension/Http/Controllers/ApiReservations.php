<?php

namespace Gridded\ApiReservationExtension\Http\Controllers;

use Igniter\Api\Classes\ApiController;
use Igniter\Reservation\Classes\BookingManager;

class ApiReservations extends ApiController
{
    public $implement = [
        'Igniter\Api\Actions\RestController',
    ];

    public $checkToken = true;

    public $guard = 'api';

    protected $defaultSort = ['reserve_id', 'desc'];

    public function create()
    {
        $data = post(); // obtiene el body JSON del request

        $bookingManager = resolve(BookingManager::class);
        $reservation = $bookingManager->loadReservation();
        $reservation = $bookingManager->saveReservation($reservation, $data);

        // Asignar mesa automáticamente
        $reservation->assignTable();

        // Confirmar automáticamente
        $reservation->status = 'confirmed';
        $reservation->save();

        return $this->createResponse($reservation);
    }
}