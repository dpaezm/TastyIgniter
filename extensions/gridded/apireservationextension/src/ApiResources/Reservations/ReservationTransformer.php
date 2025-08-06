<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationRepository;
use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationRequest;
use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationTransformer;
use Igniter\Api\Classes\ApiController;
use Igniter\Api\Http\Actions\RestController;

class ReservationsController extends ApiController
{
    public array $implement = [RestController::class];

    public array $restConfig = [
        'actions' => [ 'store' => [], ],
        'request' => ReservationRequest::class,
        'repository' => ReservationRepository::class,
        'transformer' => ReservationTransformer::class,
    ];
}