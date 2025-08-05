<?php

use Illuminate\Support\Facades\Route;
use Gridded\ApiReservationExtension\Http\Controllers\ApiReservationController;

Route::prefix('api/reservations')->group(function () {
    Route::post('/create', [ApiReservationController::class, 'store']);
});
