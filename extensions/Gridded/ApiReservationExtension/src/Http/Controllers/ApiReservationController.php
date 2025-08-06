<?php

namespace Gridded\ApiReservationExtension\Http\Controllers;

use Igniter\Reservation\Classes\BookingManager;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class ApiReservationController extends Controller
{
    public function store(Request $request)
    {
        // 1. Validar la entrada (sigue siendo importante)
        $rules = [
            'location_id'   => ['required', 'integer'],
            'guest_num'     => ['required', 'integer', 'min:1'],
            'first_name'    => ['required', 'string', 'min:2'],
            'last_name'     => ['required', 'string', 'min:2'],
            'email'         => ['required', 'email'],
            'telephone'     => ['required', 'string'],
            'reserve_date'  => ['required', 'date_format:Y-m-d'],
            'reserve_time'  => ['required', 'date_format:H:i'],
            'comment'       => ['nullable', 'string'],
        ];

        $validatedData = Validator::make($request->all(), $rules)->validate();

        $bookingManager = resolve(BookingManager::class);

        try {
            // 2. Simplemente intentamos guardar. Nuestro evento se encargará del resto.
            $reservation = $bookingManager->saveReservation(
                $bookingManager->loadReservation(),
                $validatedData
            );
        } catch (ValidationException $e) {
            // Si nuestro evento lanzó una excepción, la atrapamos y la devolvemos.
            throw $e;
        }

        // 3. Devolver la respuesta de éxito
        return response()->json([
            'success'     => true,
            'message'     => 'Reservation created and confirmed successfully.',
            'reservation' => $reservation->fresh(),
        ], 201);
    }
}