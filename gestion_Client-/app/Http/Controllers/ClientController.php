<?php

namespace App\Http\Controllers;
use App\Models\Client;
use Illuminate\Http\Request;

class ClientController extends Controller
{

   

public function index() {
    $clients = Client::all();
    return view('clients.index', compact('clients'));
}

public function create() {
    return view('clients.create');
}

public function store(Request $request) {
    $request->validate([
        'name' => 'required',
        'email' => 'required|email|unique:clients',
    ]);

    Client::create($request->all());
    return redirect()->route('clients.index')->with('success', 'Client added successfully.');
}

public function show(Client $client) {
    return view('clients.show', compact('client'));
}

public function edit(Client $client) {
    return view('clients.edit', compact('client'));
}

public function update(Request $request, Client $client) {
    $request->validate([
        'name' => 'required',
        'email' => 'required|email|unique:clients,email,' . $client->id,
    ]);

    $client->update($request->all());
    return redirect()->route('clients.index')->with('success', 'Client updated successfully.');
}

public function destroy(Client $client) {
    $client->delete();
    return redirect()->route('clients.index')->with('success', 'Client deleted successfully.');
}

}
