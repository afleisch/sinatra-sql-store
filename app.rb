require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'pg'

def storedb
  "storeadminsite"
end

def with_db
  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  yield c
  c.close
end

get '/' do
  erb :index
end

# The Products and Categories machinery:

# Get the index of products
get '/products' do
  c = PGconn.new(:host => "localhost", :dbname => "storedb")

  # Get all rows from the products table.
  @products = c.exec_params("SELECT * FROM products;")
  c.close
  erb :products
end

#Get the index of categories
get '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => "storedb")

  # Get all rows from the categories table.
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :categories
end

# Get the form for creating a new product
get '/products/new' do
  erb :new_product
end

#Get the form for creating a new category
get '/categories/new' do
  erb :new_category
end

# POST to create a new product
post '/products' do
  c = PGconn.new(:host => "localhost", :dbname => "storedb")

  # Insert the new row into the products table.
  c.exec_params("INSERT INTO products (name, price, description) VALUES ($1,$2,$3)",
                  [params["name"], params["price"], params["description"]])

  # Assuming you created your products table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_product_id = c.exec_params("SELECT currval('products_id_seq');").first["currval"]
  c.close
  redirect "/products/#{new_product_id}"
end

# POST to create a new category
post '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => "storedb")

  # Insert the new row into the categories table.
  c.exec_params("INSERT INTO categories (name) VALUES ($1)",
                  [params["name"]])

  # Assuming you created your categories table with "id SERIAL PRIMARY KEY",
  # This will get the id of the category you just created.
  new_category_id = c.exec_params("SELECT currval('categories_id_seq');").first["currval"]
  c.close
  redirect "/categories/#{new_category_id}"
end

# Update a product
post '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => "storedb")

  # Update the product.
  c.exec_params("UPDATE products SET (name, price, description) = ($2, $3, $4) WHERE products.id = $1 ",
                [params["id"], params["name"], params["price"], params["description"]])
  c.close
  redirect "/products/#{params["id"]}"
end

# Update a category
post '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => "storedb")

  # Update the category.
  c.exec_params("UPDATE categories SET (name) = ($2) WHERE categories.id = $1 ",
                [params["id"], params["name"]])
  c.close
  redirect "/categories/#{params["id"]}"
end

get '/products/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1", [params["id"]]).first
  c.close
  erb :edit_product
end

get '/categories/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  @categories = c.exec_params("SELECT * FROM categories WHERE categories.id = $1", [params["id"]]).first
  c.close
  erb :edit_category
end

# DELETE to delete a product
post '/products/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  c.exec_params("DELETE FROM products WHERE products.id = $1", [params["id"]])
  c.close
  redirect '/products'
end

#Delete a category
post '/categories/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  c.exec_params("DELETE FROM categories WHERE categories.id = $1", [params["id"]])
  c.close
  redirect '/categories'
end

# GET the show page for a particular product
get '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1;", [params[:id]]).first
  c.close
  erb :product
end

#Get the show page for a particular category
get '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  @categories = c.exec_params("SELECT * FROM categories WHERE categories.id = $1;", [params[:id]]).first
  c.close
  erb :category
end

def create_products_table
  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  c.exec %q{
  CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name varchar(255),
    price decimal,
    description text
  );
  }
  c.close
end

def create_categories_table
  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  c.exec %q{
  CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name varchar(255)
  );
  }
  c.close
end


def drop_products_table
  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  c.exec "DROP TABLE products;"
  c.close
end

def drop_categories_table
  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  c.exec "DROP TABLE categories;"
  c.close
end

def seed_products_table
  products = [["Laser", "325", "Good for lasering."],
              ["Shoe", "23.4", "Just the left one."],
              ["Wicker Monkey", "78.99", "It has a little wicker monkey baby."],
              ["Whiteboard", "125", "Can be written on."],
              ["Chalkboard", "100", "Can be written on.  Smells like education."],
              ["Podium", "70", "All the pieces swivel separately."],
              ["Bike", "150", "Good for biking from place to place."],
              ["Kettle", "39.99", "Good for boiling."],
              ["Toaster", "20.00", "Toasts your enemies!"],
             ]

  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  products.each do |p|
    c.exec_params("INSERT INTO products (name, price, description) VALUES ($1, $2, $3);", p)
  end
  c.close
end

def seed_categories_table
  categories =[["Home"],
              ["School"],
              ["Sports"],
              ["Furnishings"],
              ["Clothing"],
              ["Decoration"],
              ["Tool"],
              ["Transportation"],
              ["Appliance"],
             ]

  c = PGconn.new(:host => "localhost", :dbname => "storedb")
  categories.each do |cat|
    c.exec_params("INSERT INTO categories (name) VALUES ($1);", cat)
  end
  c.close
end

def create_product_cat_table
    c = PGconn.new(:host => "localhost", :dbname => "storedb")
  c.exec %q{
  CREATE TABLE product_cat (
    id SERIAL PRIMARY KEY,
    product_id INTEGER,
    cat_id INTEGER
  );
  }
  c.close

end
#should be equal to SELECT * FROM products
#INNER JOIN categories
# ON true;

#SELECT * FROM products AS p
#INNER JOIN product_cat AS pc
#ON pc.product_id=p_id
def seed_product_cat_table

c = PGconn.new(:host => "localhost", :dbname => "storedb")
  
@products = c.exec %q{ SELECT * FROM products;}
@categories = c.exec %q{SELECT * FROM categories;}
@product_cat = @products
      INNER JOIN @categories ON true;

  
  c.close
end