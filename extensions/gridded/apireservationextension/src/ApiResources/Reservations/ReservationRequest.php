<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Igniter\System\Classes\FormRequest;

class ReservationRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'guest_num'    => ['required', 'integer', 'min:1'],
            'first_name'   => ['required', 'string', 'min:2'],
            'telephone'    => ['required', 'string'],
            'reserve_date' => ['required', 'date_format:Y-m-d'],
            'reserve_time' => ['required', 'date_format:H:i'],
            'comment'      => ['nullable', 'string'],
            'email'        => ['nullable', 'email'], // <-- CAMBIO CLAVE: 'required' a 'nullable'
        ];
    }
}