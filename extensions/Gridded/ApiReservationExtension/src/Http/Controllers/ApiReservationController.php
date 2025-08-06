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

        // Convertimos date + time a sdateTime como pide la documentación
        $data['sdateTime'] = $data['reserve_date'] . ' ' . $data['reserve_time'];

        // Renombramos campos al formato esperado por BookingManager
        $attributes = [
            'location_id' => $data['location_id'],
            'guest'       => $data['guest_num'],
            'first_name'  => $data['first_name'],
            'last_name'   => $data['last_name'],
            'email'       => $data['email'],
            'telephone'   => $data['telephone'],
            'comment'     => $data['comment'] ?? '',
            'sdateTime'   => $data['sdateTime'],
        ];

        $booking = resolve(BookingManager::class);

        try {
            $reservation = $booking->saveReservation(
                $booking->loadReservation(),
                $attributes
            );
        } catch (ValidationException $e) {
            throw $e;
        }

        return response()->json([
            'success'     => true,
            'reservation' => $reservation,
        ], 201);
    }
}
