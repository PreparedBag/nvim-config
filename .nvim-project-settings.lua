return {
    dap = {
        ['STM32L433CC'] = {
            device    = 'stm32l433cc',
            interface = 'swd',
            speed     = '4000',
            gdb_port  = 2331,
        },
    },
    telescope = {
        extra_dirs = { },
        exclude = { },
    },
    commands = {
        {
            key = "<leader>ce",
            desc = "Example Custom Command",
            cmd = "ls -l",
            keep_open = true,
        }
    },
}
