import type { ClienteBody, ClienteResponse } from "../dto/clientes.dto.js";
import * as repo from "../repositories/clientes.repo.js";

export async function listClientes(): Promise<ClienteResponse[]> {
  return repo.list();
}

export async function getCliente(id: number): Promise<ClienteResponse | null> {
  return repo.findById(id);
}

export async function createCliente(data: ClienteBody): Promise<ClienteResponse> {
  return repo.insert(data);
}

export async function updateCliente(
  id: number,
  data: ClienteBody
): Promise<ClienteResponse | null> {
  return repo.update(id, data);
}

export async function deleteCliente(id: number): Promise<boolean> {
  return repo.remove(id);
}
