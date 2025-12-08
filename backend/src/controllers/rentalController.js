import { RentalModel } from '../models/rentalModel.js';
import { MotorcycleModel } from '../models/motorcycleModel.js';
import { success, error } from '../utils/response.js';

export async function createRental(req, res) {
  try {
    const { motorcycle_id, start_date, end_date } = req.body;
    if (!motorcycle_id || !start_date || !end_date) return error(res, 'Missing fields');
    const moto = await MotorcycleModel.find(motorcycle_id);
    if (!moto) return error(res, 'Motorcycle not found', 404);
    const days = (new Date(end_date) - new Date(start_date)) / (1000*60*60*24) + 1;
    if (days <= 0) return error(res, 'Invalid dates');
    const total_price = days * moto.price_per_day;
    const rental = await RentalModel.create({ user_id: req.user.id, motorcycle_id, start_date, end_date, total_price });
    return success(res, rental, 'Rental created');
  } catch (e) { return error(res, e.message); }
}

export async function listUserRentals(req, res) {
  try {
    const rows = await RentalModel.byUser(req.user.id);
    return success(res, rows);
  } catch (e) { return error(res, e.message); }
}

export async function listAllRentals(req, res) {
  try {
    const rows = await RentalModel.all();
    return success(res, rows);
  } catch (e) { return error(res, e.message); }
}

export async function updateStatus(req, res) {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const rental = await RentalModel.updateStatus(id, status);
    return success(res, rental, 'Status updated');
  } catch (e) { return error(res, e.message); }
}
