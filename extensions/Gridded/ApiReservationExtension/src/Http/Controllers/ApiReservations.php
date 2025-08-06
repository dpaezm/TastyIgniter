<?php

namespace Gridded\ApiReservationExtension\Http\Controllers;

use Igniter\Reservation\Classes\BookingManager;
use Igniter\Reservation\Models\ReservationStatus;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class ApiReservationController extends Controller
{
    public function store(Request $request)
    {
        $rules = [
            'location_id'   => ['required','integer'],
            'guest_num'     => ['required','integer','min:1'],
            'first_name'    => ['required','string','min:2'],
            'last_name'     => ['required','string','min:2'],
            'email'         => ['required','email'],
            'telephone'     => ['required','string'],
            'reserve_date'  => ['required','date_format:Y-m-d'],
            'reserve_time'  => ['required','date_format:H:i'],
            'comment'       => ['nullable','string'],
        ];

        $data = Validator::make($request->all(), $rules)->validate();

        $booking = resolve(BookingManager::class);

        try {
            // 1. Crear/guardar la reserva
            $reservation = $booking->saveReservation(
                $booking->loadReservation(),
                $data
            );
        } catch (ValidationException $e) {
            throw $e;          // Devuelve 422 si no hay disponibilidad
        }

        // 2. Asignar mesa automáticamente
        $reservation->assignTable();

        // 3. Confirmar si se asignó al menos una mesa
        if ($reservation->tables()->count()) {
            $confirmedStatus = ReservationStatus::where('flag', 'confirm')->value('status_id');
            $reservation->status_id = $confirmedStatus;   // confirmado ✅
        }

        $reservation->save();

        return response()->json([
            'success'     => true,
            'reservation' => $reservation,
        ], 201);
    }
}
