<?php

namespace Gridded\ApiReservationExtension\Http\Controllers;

use Illuminate\Routing\Controller;
use Illuminate\Http\Request;
use Igniter\Reservation\Classes\BookingManager;

class ApiReservationController extends Controller
{
    public function store(Request $request)
    {
        $attributes = $request->validate([
            'location_id' => 'required|integer',
            'guest' => 'required|integer|min:1',
            'first_name' => 'required|string',
            'last_name' => 'nullable|string',
            'email' => 'required|email',
            'telephone' => 'required|string',
            'sdateTime' => 'required|string',
            'comment' => 'nullable|string',
        ]);

        $bookingManager = resolve(BookingManager::class);

        $reservation = $bookingManager->loadReservation();
        $reservation = $bookingManager->saveReservation($reservation, $attributes);

        $reservation->assignTable();
        $reservation->status = 'confirmed';
        $reservation->save();

        return response()->json([
            'success' => true,
            'reservation' => $reservation,
        ]);
    }
}
