<?php

namespace Gridded\ApiReservationExtension;

use System\Classes\BaseExtension;

class Extension extends BaseExtension
{
    public function register()
    {
    }

    public function boot()
    {
    }

    public function registerRoutes()
    {
        \System\Classes\RouteRegistrar::instance()->registerRoutesFromFile(__DIR__.'/routes.php');
    }
}
