<?php

namespace Gridded\ApiReservationExtension\ApiResources\Reservations;

use Igniter\System\Classes\FormRequest;

class ReservationRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'location_id'  => ['required', 'integer'],
            'guest_num'    => ['required', 'integer'],
            'first_name'   => ['required', 'string'],
            'last_name'    => ['required', 'string'],
            'email'        => ['required', 'email'],
            'telephone'    => ['required', 'string'],
            'reserve_date' => ['required', 'date_format:Y-m-d'],
            'reserve_time' => ['required', 'date_format:H:i'],
        ];
    }
}