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
        // 1. Validar la entrada con los nombres de campo correctos
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

        // 2. Crear un objeto de reserva en memoria
        $reservation = $bookingManager->loadReservation();
        $reservation->fill($validatedData);

        // 3. Forzar la asignación de una mesa (Paso de disponibilidad)
        $tableAssigned = $bookingManager->assignReservationTable($reservation);

        // 4. Si no hay mesa, lanzar un error claro
        if (!$tableAssigned) {
            throw ValidationException::withMessages([
                'reserve_time' => 'No tables available for the selected date and time.',
            ]);
        }

        // 5. Solo ahora, guardar la reserva. El estado se aplicará automáticamente.
        $bookingManager->saveReservation($reservation, $validatedData);

        // 6. Devolver la respuesta final
        return response()->json([
            'success'     => true,
            'message'     => 'Reservation created and confirmed successfully.',
            'reservation' => $reservation->fresh(),
        ], 201);
    }
}
