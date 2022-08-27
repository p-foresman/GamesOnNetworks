using Graphs, JSON3

function adjMatrixStringParserOld(db_matrix_string)
    string = chop(db_matrix_string, head=1, tail=1)
    new_vector = Vector{Int64}([])
    for i in string #parse the string into a vector
        if i != ' ' && i != ';'
            push!(new_vector, parse(Int64, i))
        end
    end
    size = Int64(sqrt(length(new_vector))) #will always be a perfect square due to matrix being adjacency matrix
    new_matrix = reshape(new_vector, (size, size)) #reshape parsed vector into matrix (this result can be fed into the SimpleGraph() function)
    return new_matrix
end

function adjMatrixStringParser(db_matrix_string::String)
    new_vector = JSON3.read(db_matrix_string)
    size = Int64(sqrt(length(new_vector))) #will always be a perfect square due to matrix being adjacency matrix
    new_matrix = reshape(new_vector, (size, size)) #reshape parsed vector into matrix (this result can be fed into the SimpleGraph() function)
    return new_matrix
end


payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                        (0, 0) (50, 50) (50, 30);
                                        (30, 70) (30, 50) (30, 30)])

string = JSON3.write(payoff_matrix)


function payoffMatrixStringParser(db_matrix_string)
    new_vector = JSON3.read(db_matrix_string)
    tuple_vector = Vector{Tuple{Int8, Int8}}([])
    for index in new_vector
        new_tuple = Tuple{Int8, Int8}([index[1], index[2]])
        push!(tuple_vector, new_tuple)
    end
    size = Int64(sqrt(length(tuple_vector)))
    new_matrix = reshape(tuple_vector, (size, size))
    return new_matrix
end

new_matrix = payoffMatrixStringParser(string)

println(new_matrix == payoff_matrix)




