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

        $data = Validator::make($request->all(), $rules)->validate();

        $bookingManager = resolve(BookingManager::class);

        try {
            $reservation = $bookingManager->saveReservation(
                $bookingManager->loadReservation(),
                $data
            );
        } catch (ValidationException $e) {
            throw $e;
        }

        // ✅ Asigna automáticamente una mesa
        $reservation->assignTable();

        // ✅ Si hay mesa, marca la reserva como confirmada (dispara los hooks del sistema)
        if ($reservation->tables()->count()) {
            $reservation->markAs('confirm'); // esto es lo que cambia todo
        }

        $reservation->save();

        return response()->json([
            'success'     => true,
            'reservation' => $reservation,
        ], 201);
    }
}
