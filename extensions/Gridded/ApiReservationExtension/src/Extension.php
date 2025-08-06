<?php

namespace Gridded\ApiReservationExtension;

use Igniter\Reservation\Classes\BookingManager;
use Igniter\System\Classes\BaseExtension;
use Igniter\System\Classes\RouteRegistrar;
use Illuminate\Support\Facades\Event;
use Illuminate\Validation\ValidationException;

class Extension extends BaseExtension
{
    public function boot()
    {
        // Escuchamos el evento que se dispara ANTES de guardar una reserva.
        Event::listen('igniter.reservation.beforeSaveReservation', function ($reservation, $data) {
            // Solo actuamos si la reserva aún no tiene una mesa asignada.
            if ($reservation->table_id) {
                return;
            }

            $bookingManager = resolve(BookingManager::class);

            // Intentamos asignarle una mesa.
            $tableAssigned = $bookingManager->assignReservationTable($reservation);

            // Si no se pudo asignar una mesa, lanzamos una excepción.
            // Esto detendrá el proceso de guardado y devolverá un error 422 a la API.
            if (!$tableAssigned) {
                throw ValidationException::withMessages([
                    'reserve_time' => 'No tables available for the selected date and time.',
                ]);
            }

            // Si se asignó una mesa, el sistema continuará y la guardará
            // con el table_id y el estado por defecto (Confirmed).
        });
    }

    public function registerRoutes()
    {
        RouteRegistrar::instance()->registerRoutesFromFile(__DIR__.'/routes.php');
    }
}