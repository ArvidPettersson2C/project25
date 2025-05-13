require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
enable :sessions

#Todo:
  #HJÄLPFUNKTIONER
#Hem:
  #Checkbox för att bli admin *
#layout:
  #Plånbok *
#Visa produkter:
  #Ta bort ska inte finnas för andra användare *
  #Köpa produkter
  #Podukts kostnad och mängd rubriker *
  #Gör så att produkter inte är länkar *
  #Lägga till i kundvagn *
  #Kundvagn som section *
  #Användarvalidering
  #Ändra pris och mängd på befintliga produkter *
  #Lägg till produkter specifikt admin *
#Köplogik:
  #Logga in för att köpa
  #Summa i plånbok ska minska
  #Mängd ska minskas
  #produkt ska tas bort om mängd är 0
  #Fylla på plånbok

before(['/products', '/products/delete', '/products/update']) do
  if session[:admin] != 1
    redirect('/error/Not_admin')
  end
end

def db_connection()
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  return db
end

get('/') do
  slim(:start)
end

# Display products
get('/products/') do
  db = db_connection()
  user_cart = db.execute("SELECT * FROM products WHERE id IN (SELECT productid FROM cart WHERE userid = ?)", session[:user_id])
  cart = db.execute("SELECT * FROM cart WHERE userid = ?", session[:user_id])

  products = db.execute("SELECT * FROM products")
  slim(:"products/index", locals: { products: products, user_cart: user_cart, cart: cart })
end

post('/cart/update') do
  product_id = params[:id].to_i
  amount = params[:amount].to_i
  db = db_connection()
  stock = db.execute("SELECT stock FROM products WHERE id = ?", product_id).first["stock"]
  if stock - amount < 0
    redirect('/error/Not_enough_stock')
  end
  if amount <= 0
    redirect('/error/Invalid_amount')
  end

  db.execute("UPDATE products SET stock = stock - ? WHERE id = ?", [amount, product_id])

  if db.execute("SELECT * FROM cart WHERE userid = ? AND productid = ?", [session[:user_id], product_id]).empty?
    db.execute("INSERT INTO cart (userid, productid, amount) VALUES (?, ?, ?)", [session[:user_id], product_id, amount])
  else
    db.execute("UPDATE cart SET amount = amount + ? WHERE userid = ? AND productid = ?", [amount, session[:user_id], product_id])
  end
  redirect('/products/')
end

get('/products/new') do
  slim(:"products/new")
end

post('/products') do
  name = params[:name]
  description = params[:description]
  price = params[:price].to_i
  stock = params[:stock].to_i

  db = db_connection()
  db.execute("INSERT INTO products (name, description, price, stock) VALUES (?,?,?,?)", [name, description, price, stock])
  redirect('/products/')
end

post("/products/delete") do
  id = params[:id].to_i
  db = db_connection()
  db.execute("DELETE FROM products WHERE id = ?", id)
  redirect('/products/')
end

post('/products/update') do
  id = params[:id].to_i
  price = params[:price].to_i
  stock = params[:stock].to_i
  name = params[:name]
  db = db_connection()
  db.execute("UPDATE products SET price=?, stock=? WHERE id = ?", [price, stock, id])
  redirect('/products/')
end

#Error hantering
get('/error/:message') do
  return params[:message]
end

#Login:
# Login logic
post('/login') do
  user_name = params["user_name"]
  password = params["password"]

  db = db_connection()
  
  result = db.execute("SELECT * FROM users WHERE user_name = ?", user_name).first
  puts result
  
  if result && BCrypt::Password.new(result["passworddigest"]) == password
    session[:user_id] = result["id"]
    session[:user_name] = result["user_name"]
    session[:admin] = result["admin"]
    session[:money] = result["money"]
    puts session[:user_id]
    redirect('/products/')
  else
    redirect('/error/Invalid_username_or_password')
  end
end

# Register logic
post('/register') do
  user_name = params["user_name"]
  password = params["password"]
  password_confirmation = params["password_confirmation"]
  admin = params["admin"] == "on" ? 1 : 0

  if user_name.empty? || password.empty? || password_confirmation.empty?
    redirect('/error/All_fields_are_required')
  end

  db = db_connection()
  result = db.execute("SELECT * FROM users WHERE user_name = ?", user_name)

  if result.empty?
    if password == password_confirmation
      password_digest = BCrypt::Password.create(password)
      db.execute("INSERT INTO users (user_name, passworddigest, money, admin) VALUES (?, ?, ?, ?)", [user_name, password_digest, 100, admin])
      redirect('/')
    else
      redirect('/error/Passwords_do_not_match')
    end
  else
    redirect('/error/Username_already_taken')
  end
end

# Logout logic
get('/logout') do
  session.clear
  redirect('/')
end

