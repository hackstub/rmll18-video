#!/usr/bin/env python3

import os
import signal
import subprocess
import threading

from colored import fg, attr
from pathlib import Path


class Logger:
    COLORS = [
        fg(1),  # red
        fg(2),  # green
        fg(3),  # yellow
        fg(4),  # blue
        fg(5),  # magenta
        fg(6),  # cyan
    ]
    COLORS_SIZE = len(COLORS)
    NAME_LENGTH = 5
    RESET = attr(0)
    __index = 0
    __lock = threading.Semaphore()

    @staticmethod
    def get(name):
        color = Logger.COLORS[Logger.__index % Logger.COLORS_SIZE]
        Logger.__index += 1
        return Logger(name, color)

    def __init__(self, name, color):
        name = name.rjust(Logger.NAME_LENGTH, " ")
        self.__prefix = "[%s%s%s] " % (color, name, Logger.RESET)

    def log(self, line, end="\n"):
        if isinstance(line, bytes):
            line = line.decode()
        with Logger.__lock:
            print(self.__prefix + line, end=end)

    def stdout(self, line, end="\n"):
        self.log(line, end=end)

    def stderr(self, line, end="\n"):
        if isinstance(line, bytes):
            line = line.decode()
        line = "%s%s%s" % (fg(1), line, Logger.RESET)
        self.log(line, end=end)


class Cmd:
    @staticmethod
    def process(io, logger):
        for line in io:
            logger(line, end="")

    def __init__(self, logger, *args, **kwargs):
        self.__logger = logger
        self.__args = args
        self.__kwargs = kwargs
        self.__process = None

    def run(self):
        env = self.__kwargs.pop("env", None)
        if env:
            env = os.environ.update(env)
        cwd = self.__kwargs.pop("cwd", None)

        self.__logger.log(" ".join(self.__args))
        self.__process = subprocess.Popen(self.__args,
                                          stdin=subprocess.PIPE,
                                          stdout=subprocess.PIPE,
                                          stderr=subprocess.PIPE, env=env,
                                          cwd=cwd)
        threads = [
            threading.Thread(target=Cmd.process, args=[self.__process.stdout,
                                                       self.__logger.stdout]),
            threading.Thread(target=Cmd.process,
                             args=[self.__process.stderr, self.__logger.stderr])
        ]

        stdin = self.__kwargs.get("stdin")
        if stdin:
            self.__process.stdin.write(stdin)

        [thread.start() for thread in threads]
        retcode = self.__process.wait()
        for thread in threads:
            thread.join()
        self.__process = None

        self.__logger.log(" ".join(self.__args) + ": " + str(retcode))
        if retcode:
            raise subprocess.CalledProcessError(retcode, self.__args)

    def signal(self, signal=signal.SIGTERM):
        if self.__process:
            try:
                self.__process.send_signal(signal)
            except:
                pass

    @staticmethod
    def rsync(logger, *args):
        cmd = ["rsync", "-rv", "--partial", "--inplace", "--delete",
               "-e", "ssh -o ControlMaster=no -o ControlPath=none"] \
              + list(args)
        return Cmd(logger, *cmd)


class Loop(threading.Thread):
    def __init__(self, logger, cmd):
        super().__init__()
        self.__logger = logger
#        if not isinstance(cmd, Cmd):
#            cmd = Cmd(self.__logger, cmd)
        self.__cmd = cmd
        self.__current = None
        self.__event = threading.Event()
        self.__running = False

    def run(self):
        self.__running = True
        while self.__running:
            try:
                # self.__logger.stdout("Run")
                for cmd in self.__cmd:
                    self.__current = cmd.run()
                self.__current = None
                # self.__logger.stdout("Sleep")
                self.__event.clear()
                self.__event.wait(1)
                # self.__logger.stdout("End sleep")
            except:
                pass
            # finally:
            #     self.__logger.stdout("Runned")
        # self.__logger.stdout("Exit")

    def stop(self):
        if self.__running:
            # self.__logger.stdout("Stopping")
            self.__running = False
            if self.__current:
                self.__current.signal()
            self.__event.set()
            # self.__logger.stdout("Stopping ok")
            self.join()
            # self.__logger.stdout("Stopped")


class Stream(Loop):
    def __init__(self, name, target):
        logger = Logger.get(name)
        folder = os.path.join("stream", name) + "/"
        target_stream = os.path.join(target, name) + "/"
        cmd1 = Cmd.rsync(logger, folder, target_stream)
        index = os.path.join("stream", name + ".m3u8")
        cmd2 = Cmd.rsync(logger, index, target)
        super().__init__(logger, [cmd1, cmd2])

class Streams:
    NAMES = ["360p", "480p", "720p", "1080p", "audio"]

    def __init__(self, target):
        self.__streams = []
        for name in Streams.NAMES:
            folder = os.path.join("stream", name)
            if Path(folder).is_dir():
                stream = Stream(name, target)
                self.__streams.append(stream)

    def start(self):
        for stream in self.__streams:
            stream.start()

    def stop(self):
        for stream in self.__streams:
            stream.stop()


if __name__ == "__main__":
    lock = threading.Event()

    streams = Streams("rabbit:/var/www/live")

    def signal_handler(_1, _2):
        streams.stop()
        lock.set()


    signal.signal(signal.SIGINT, signal_handler)

    streams.start()
    lock.wait()
