require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

get('/')  do
    slim(:start)
  end 
  
  get('/products') do
    db = SQLite3::Database.new("db/chinook-crud.db") #ändra databas
    db.results_as_hash = true
    result = db.execute("SELECT * FROM products") 
    p result
    slim(:"products/index",locals:{products:result})
  
  
  
  end
  
  get('/products/new') do
    slim(:"products/new")
  end
  
  post('/products/new') do
    title = params[:title]
    seller_id = params[:seller_id].to_i  
    p "vi fick in datan #{title} och #{seller_id}"
    db = SQLite3::Database.new("db/chinook-crud.db") #ändra databas
    db.execute("INSERT INTO products (Title, SellerId) VALUES (?,?)",[title, seller_id])
    redirect('/products')
  end
  
  post('/products/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/chinook-crud.db") #ändra databas
    db.execute("DELETE FROM products WHERE ProductId = ?",id)
    redirect('/products')
  end
  
  post('/products/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    artist_id = params[:artistId].to_i
    db = SQLite3::Database.new("db/chinook-crud.db")#ändra databas
    db.execute("UPDATE products SET Title=?,SellerId=? WHERE ProductId = ?",[title,seller_id,id])
    redirect('/products')
  
  end
  
  get('/products/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/chinook-crud.db")#ändra databas
    db.results_as_hash = true
    result = db.execute("SELECT * FROM products WHERE ProductId = ?",id).first
    slim(:"/products/edit",locals:{result:result})
  end
  
  get('/products/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/chinook-crud.db")#ändra databas
    db.results_as_hash = true
    result = db.execute("SELECT * FROM products WHERE ProductId = ?",id).first
    result2 = db.execute("SELECT Name FROM Sellers WHERE SellerID IN (SELECT SellerID FROM Products WHERE ProductID = ?)", id).first
    slim(:"products/show",locals:{result:result,result2:result2})
  end