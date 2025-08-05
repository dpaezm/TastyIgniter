<?php

namespace Gridded\ApiReservationExtension;

use System\Classes\BaseExtension;
use System\Classes\RouteRegistrar;

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
        RouteRegistrar::instance()->registerRoutesFromFile(__DIR__.'/routes.php');
    }
}
