<?php

use Illuminate\Support\Facades\Route;
use Gridded\ApiReservationExtension\Http\Controllers\ApiReservationController;

Route::post('/api/reservations/create-custom', [ApiReservationController::class, 'store']);
