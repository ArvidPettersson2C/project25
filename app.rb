require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

get('/')  do
    slim(:start)
  end 
  #Display products
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
    
    #p "vi fick in datan #{name} och #{id}"
    db = SQLite3::Database.new("db/database.db") #ändra databas
    db.execute("INSERT INTO products (name, description, price, stock) VALUES (?,?,?,?)",[name, description, price, stock])
    redirect('/products')
  end
  
  post('/products/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/database.db")
    db.execute("DELETE FROM products WHERE ProductId = ?", id)
    redirect('/products')
  end
  
  post('/products/:id/update') do
    id = params[:id].to_i
    name = params[:name]
    artist_id = params[:artistId].to_i
    db = SQLite3::Database.new("db/database.db")#ändra databas
    db.execute("UPDATE products SET name=? WHERE ProductId = ?",[name,seller_id,id])
    redirect('/products')
  end 
  
  get('/products/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/database.db")#ändra databas
    db.results_as_hash = true
    result = db.execute("SELECT * FROMproducts WHERE ProductId = ?",id).first
    slim(:"/products/edit",locals:{result:result})
  end
  
  get('/products/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/database.db")#ändra databas
    db.results_as_hash = true
    result = db.execute("SELECT * FROMproducts WHERE ProductId = ?",id).first
    result2 = db.execute("SELECT Name FROM Sellers WHERE SellerID IN (SELECT SellerID FROM Products WHERE ProductID = ?)", id).first
    slim(:"products/show",locals:{result:result,result2:result2})
  end
  