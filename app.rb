require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

get('/') do
  slim(:start)
end

# Display products
get('/products') do
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM products")
  slim(:"products/index", locals: { products: result })
end

get('/products/new') do
  slim(:"products/new")
end

post('/products/new') do
  name = params[:name]
  description = params[:description]
  price = params[:price].to_i
  stock = params[:stock].to_i

  db = SQLite3::Database.new("db/database.db")
  db.execute("INSERT INTO products (name, description, price, stock) VALUES (?,?,?,?)", [name, description, price, stock])
  redirect('/products')
end

post("/products/delete") do
  puts 'test'
  id = params[:id].to_i
  db = SQLite3::Database.new("db/database.db")
  db.execute("DELETE FROM products WHERE id = ?", id)
  redirect('/products')
end

post('/products/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  artist_id = params[:artistId].to_i
  db = SQLite3::Database.new("db/database.db")
  db.execute("UPDATE products SET name=? WHERE ProductId = ?", [name, id])
  redirect('/products')
end

get('/products/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM products WHERE ProductId = ?", id).first
  slim(:"/products/edit", locals: { result: result })
end

get('/products/:id') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM products WHERE ProductId = ?", id).first
  result2 = db.execute("SELECT Name FROM Sellers WHERE SellerID IN (SELECT SellerID FROM Products WHERE ProductID = ?)", id).first
  slim(:"products/show", locals: { result: result, result2: result2 })
end

#Login:
# Login logic
post('/login') do
  user_name = params["user_name"]
  password = params["password"]

  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE user_name = ?", user_name).first

  if result && BCrypt::Password.new(result["password_digest"]) == password
    session[:user_id] = result["id"]
    redirect('/products')
  else
    set_error("Invalid username or password")
    redirect('/error')
  end
end

# Register logic
post('/register') do
  user_name = params["user_name"]
  password = params["password"]
  password_confirmation = params["password_confirmation"]

  db = SQLite3::Database.new("db/database.db")
  result = db.execute("SELECT * FROM users WHERE user_name = ?", user_name)

  if result.empty?
    if password == password_confirmation
      password_digest = BCrypt::Password.create(password)
      db.execute("INSERT INTO users (user_name, password_digest) VALUES (?, ?)", [user_name, password_digest])
      redirect('/register_confirmation')
    else
      set_error("Passwords do not match")
      redirect('/error')
    end
  else
    set_error("User already exists")
    redirect('/error')
  end
end

# Logout logic
get('/logout') do
  session.clear
  redirect('/')
end