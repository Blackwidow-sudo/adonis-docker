import type { HttpContext } from '@adonisjs/core/http'
import Todo from '#models/todo'
import { createTodoValidator } from '#validators/todo'

export default class TodosController {
  /**
   * Display a list of resource
   */
  async index({ view }: HttpContext) {
    const todos = await Todo.all()

    return view.render('pages/todos', { todos })
  }

  /**
   * Display form to create a new record
   */
  async create({}: HttpContext) {}

  /**
   * Handle form submission for the create action
   */
  async store({ request, view }: HttpContext) {
    const payload = await request.validateUsing(createTodoValidator)

    const todo = await Todo.create(payload)

    return view.render('components/todo_item', { todo })
  }

  /**
   * Show individual record
   */
  async show({ params }: HttpContext) {}

  /**
   * Edit individual record
   */
  async edit({ params }: HttpContext) {}

  /**
   * Handle form submission for the edit action
   */
  async update({ params, request }: HttpContext) {}

  /**
   * Delete record
   */
  async destroy({ params, response }: HttpContext) {
    const todo = await Todo.findOrFail(params.id)
    await todo.delete()

    return response.status(200)
  }
}
