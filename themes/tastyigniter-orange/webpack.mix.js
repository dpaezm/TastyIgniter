const mix = require('laravel-mix');

mix.setPublicPath('public') // esto es clave
   .sass('resources/assets/sass/main.scss', 'assets/css')
   .js('resources/assets/js/app.js', 'assets/js')
   .version();
