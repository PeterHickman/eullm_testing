#!/bin/sh

export PATH=$PATH:/opt/homebrew/bin:/usr/local/bin

NOT_OLLAMA=11435

is_the_server_up() {
  X=`ps ax | grep '/usr/local/bin/eullm serve' | grep -v grep`

  if [ -z "$X" ]; then
    echo "ERROR: The server is not running"
  else
    echo "The server is running"
  fi
}

is_the_server_down() {
  X=`ps ax | grep '/usr/local/bin/eullm serve' | grep -v grep`

  if [ -z "$X" ]; then
    echo "The server is not running"
  else
    echo "ERROR: The server is still running"
  fi
}

to() {
  echo "TEST_START"

  is_the_server_up

  timeout 10m "$@"
  if [ $? -ne 0 ]; then
    echo "ERROR: Process timed out after 10 minutes"
  fi

  echo
  echo "TEST_END"
}

start_server() {
  [ -e /tmp/eullm.log ] && rm /tmp/eullm.log

  echo "Server started with --port ${NOT_OLLAMA} ${SERVER_ARGS}"

  eullm serve --daemon --port ${NOT_OLLAMA} --pidfile /tmp/eullm.pid ${SERVER_ARGS}
  sleep 5
}

dump_log() {
  echo
  echo "== Dumping server log /tmp/eullm.log after server shutdown"
  echo
  cat /tmp/eullm.log
  echo
  echo "== End of dump"
  echo
}

sys_info() {
  HOST=`uname`

  if [ ${HOST} = 'Darwin' ]; then
    OS_NAME="macOS $(sw_vers -productVersion)"
    KERNEL_VER=$(uname -r | awk '{print $1}')
    CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || sysctl -n cpufamily)

    GPU_INFO=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model:" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ *$//')

    MEM_TOTAL=$(sysctl -n hw.memsize | awk '{printf "%.1f GiB", $1/1024/1024/1024}')

    printf "OS:      %s\n" "$OS_NAME"
    printf "Kernel:  %s\n" "$KERNEL_VER"
    printf "CPU:     %s\n" "$CPU_MODEL"
    printf "GPU:     %s\n" "$GPU_INFO"
    printf "Memory:  %s\n" "$MEM_TOTAL"
    echo ""
  elif [ ${HOST} = 'Linux' ]; then
    if [ -f /etc/os-release ]; then
        OS_NAME=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
    elif [ -f /etc/arch-release ]; then
        OS_NAME="Arch Linux"
    else
        OS_NAME="Linux"
    fi

    KERNEL_VER=$(uname -r)

    CPU_MODEL=$(grep "Model" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ //')

    MEM_TOTAL=$(awk '/MemTotal/ {printf "%.1f GiB", $2/1024/1024}' /proc/meminfo)

    printf "%-12s%s\n" "OS:" "$OS_NAME"
    printf "%-12s%s\n" "Kernel:" "$KERNEL_VER"
    printf "%-12s%s\n" "CPU:" "$CPU_MODEL"
    printf "%-12s%s\n" "Memory:" "$MEM_TOTAL"
    echo ""
  fi
}

sys_info

eullm -V

echo
echo

eullm list

echo
echo

SERVER_ARGS="--rust-debug --batch-size 4 --no-flash-attn"
start_server

echo
echo

echo TESTING http://localhost:${NOT_OLLAMA}/api/chat with simple query
echo
to curl -X POST http://localhost:${NOT_OLLAMA}/api/chat -H "Content-Type: application/json" -d '{"model":"qwen3-0.6b","messages":[{"role":"user","content":"Hello!"}],"stream":false}'

echo
echo

echo TESTING http://localhost:${NOT_OLLAMA}/v1/chat/completions with simple query
echo
to curl -X POST http://localhost:${NOT_OLLAMA}/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"qwen3-0.6b","messages":[{"role":"user","content":"Hi!"}]}'

echo
echo

echo TESTING http://localhost:${NOT_OLLAMA}/api/chat with longer query
echo
to curl -X POST http://localhost:${NOT_OLLAMA}/api/chat -H "Content-Type: application/json" -d '{"model":"qwen3-0.6b","messages":[{"role":"user","content":"why is 2 a prime number when all the rest are odd numbers?"}],"stream":false}'

echo
echo

echo TESTING http://localhost:${NOT_OLLAMA}/v1/chat/completions with longer query
echo
to curl -X POST http://localhost:${NOT_OLLAMA}/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"qwen3-0.6b","messages":[{"role":"user","content":"why is 2 a prime number when all the rest are odd numbers?"}]}'

echo
echo

kill -9 `cat /tmp/eullm.pid`
sleep 10
is_the_server_down
echo
echo

dump_log

SERVER_ARGS="--rust-debug --batch-size 4 --cache-type-k q4_0 --cache-type-v q4_0 --no-flash-attn"
start_server

echo TESTING http://localhost:${NOT_OLLAMA}/api/chat with longer query
echo
to curl -X POST http://localhost:${NOT_OLLAMA}/api/chat -H "Content-Type: application/json" -d '{"model":"qwen3-0.6b","messages":[{"role":"user","content":"why is 2 a prime number when all the rest are odd numbers?"}],"stream":false}'

echo
echo

echo TESTING http://localhost:${NOT_OLLAMA}/v1/chat/completions with longer query
echo
to curl -X POST http://localhost:${NOT_OLLAMA}/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"qwen3-0.6b","messages":[{"role":"user","content":"why is 2 a prime number when all the rest are odd numbers?"}]}'

echo
echo

kill -9 `cat /tmp/eullm.pid`
sleep 5

dump_log
