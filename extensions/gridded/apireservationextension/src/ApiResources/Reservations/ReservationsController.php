<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Igniter\Api\Classes\ApiController;
use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationRequest;
use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationTransformer;
use Gridded\ApiReservationExtension\ApiResources\Reservations\ReservationRepository;

class ReservationsController extends ApiController
{
    public function store(
        ReservationRequest $request,
        ReservationRepository $repository,
        ReservationTransformer $transformer
    ) {
        // Obtenemos los datos validados del ReservationRequest
        $validatedData = $request->validated();

        // Llamamos a nuestro método personalizado en el repositorio
        $newReservation = $repository->createReservation($validatedData);

        // Devolvemos la respuesta formateada por el Transformer
        return $this->response()->created($newReservation, $transformer);
    }
}