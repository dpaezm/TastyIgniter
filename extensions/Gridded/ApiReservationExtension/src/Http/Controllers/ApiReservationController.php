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
        // Validar la solicitud
        $rules = [
            'location_id'   => ['required', 'integer'],
            'guest_num'     => ['required', 'integer', 'min:1'],
            'first_name'    => ['required', 'string'],
            'last_name'     => ['required', 'string'],
            'email'         => ['required', 'email'],
            'telephone'     => ['required', 'string'],
            'reserve_date'  => ['required', 'date_format:Y-m-d'],
            'reserve_time'  => ['required', 'date_format:H:i'],
            'comment'       => ['nullable', 'string'],
        ];

        $data = Validator::make($request->all(), $rules)->validate();

        $booking = resolve(BookingManager::class);

        // Combinar fecha + hora en un solo campo que entiende BookingManager
        $sdateTime = $data['reserve_date'] . ' ' . $data['reserve_time'];

        // Inyectar sdateTime que sí es usado por BookingManager internamente
        $data['sdateTime'] = $sdateTime;

        // Cargar reserva en memoria
        $reservation = $booking->loadReservation();

        // Rellenar los datos
        $reservation->fill($data);

        // Verificar disponibilidad total (fecha, hora, aforo, configuración, etc)
        if (!$booking->isAvailable($reservation, $data)) {
            throw ValidationException::withMessages([
                'reserve_time' => 'No availability for the selected date and time.',
            ]);
        }

        // Asignar mesa disponible (con lógica de aforo y colisiones)
        if (!$booking->assignReservationTable($reservation)) {
            throw ValidationException::withMessages([
                'reserve_time' => 'No tables available at this time.',
            ]);
        }

        // Asignar estado "confirmado"
        $statusId = ReservationStatus::where('flag', 'confirm')->value('status_id');
        $reservation->status_id = $statusId;

        // Guardar en base de datos
        $reservation = $booking->saveReservation($reservation, $data);

        return response()->json([
            'success' => true,
            'message' => 'Reservation created successfully',
            'reservation' => $reservation->fresh(),
        ], 201);
    }
}