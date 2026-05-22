module.exports = {
  apps: [
    {
      name: "builder",
      cwd: "C:\\typebot",
      script: "cmd.exe",
      args: '/c bunx nx start builder -p 3001',

      autorestart: true,
      restart_delay: 2000,
      max_restarts: 15,
//      max_memory_restart: "1G",

      watch: false,
      instances: 1,

      error_file: "./logs/builder-error.log",
      out_file: "./logs/builder-out.log",
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      combine_logs: true
    },

    {
      name: "viewer",
      cwd: "C:\\typebot",
      script: "cmd.exe",
      args: '/c bunx nx start viewer -p 3002',   // ← Change port if needed

      autorestart: true,
      restart_delay: 2000,
      max_restarts: 15,
//      max_memory_restart: "1G",

      watch: false,
      instances: 1,

      error_file: "./logs/viewer-error.log",
      out_file: "./logs/viewer-out.log",
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      combine_logs: true
    }
  ]
};