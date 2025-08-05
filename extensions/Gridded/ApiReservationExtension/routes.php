<?php

Route::group([
    'prefix' => 'api',
    'middleware' => ['api'],
    'namespace' => 'Gridded\ApiReservationExtension\Http\Controllers',
], function () {
    Route::post('reservations', 'ApiReservations@create');
});