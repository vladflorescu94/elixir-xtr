require Logger

defmodule Xtr do
  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    Logger.info "Client connected"
    {:ok, pid} = Task.Supervisor.start_child(Xtr.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, str} = :gen_tcp.recv(socket, 0)
    Xtr.Command.exec(str)
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
