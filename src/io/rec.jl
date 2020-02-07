"load rec file"

function load_rec(fname::String)
    open(fname) do io
        header = reinterpret(Int32, read(io, 16))
        nx, ny, nz, ntype = header[1], header[2], header[3], header[4]
        
        if ntype == 0
            dtype = UInt8
        elseif ntype == 1
            dtype = Int16
        elseif ntype == 2
            dtype = Float32
        elseif ntype == 6
            dtype = UInt16
        else
            error("Datatype error")
        end
        println("nx: $nx, ny: $ny, nz: $nz")

        # skip other headers
        seek(io, 92)
        header_size = reinterpret(Int32, read(io, 4))[1]
        seek(io, 1024 + header_size)

        # read data
        img_ = Array{dtype}(reinterpret(dtype, read(io, nx*ny*nz*sizeof(dtype))) )
        img = reshape(img_, Int(nx), Int(ny), Int(nz))

        println("for FEI conversion, we need to rotate 90 degree, but we didn't support yet.")
    end
end
