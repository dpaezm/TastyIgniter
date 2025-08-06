<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Igniter\Api\Classes\ApiController;
use Igniter\Api\Http\Actions\RestController;
use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationRequest;
use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationTransformer;
use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationRepository;

class ReservationsController extends ApiController
{
    public array $implement = [RestController::class];

    public array $restConfig = [
        'actions' => [
            'store' => [],
        ],
        'request' => ReservationRequest::class,
        'repository' => ReservationRepository::class,
        'transformer' => ReservationTransformer::class,
    ];
}