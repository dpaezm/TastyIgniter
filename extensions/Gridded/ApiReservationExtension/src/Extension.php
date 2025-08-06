<?php

namespace Gridded\ApiReservationExtension;

use Igniter\System\Classes\BaseExtension;
use Igniter\System\Classes\RouteRegistrar;


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
