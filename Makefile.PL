use inc::Module::Install;

requires
    'Test::More' => 0,
    'Exporter'   => 0;

all_from 'lib/Test/TrapWarnings.pm';
repository 'git://github.com/ichesnokov/RTx-FillTicketData.git';
WriteAll;
