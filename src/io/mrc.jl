"load rec file"

function load_mrc(fname::String)

    meta = Dict{String, Array{Int64,1}}()
    
    open(fname) do io
        header = reinterpret(Int32, read(io, 16))
        nx, ny, nz, ntype = header[1], header[2], header[3], header[4]
        
        ProjectionAngles = zeros(Float32, nz)

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
        if header_size > 0
            for i=1:nz
                seek(io, 1024+(i-1)*128)
                ang = reinterpret(Float32, read(io, 4))[1]
                ProjectionAngles[i] = ang # alpha tilt angles
            end

            # pixel size
            seek(io, 1024+ 11*4)
            val = reinterpret(Float32, read(io, 4))[1]
            push!(meta, "pixelsize" => val)

            # magnification
            seek(io, 1024+ 12*4)
            val = reinterpret(Float32, read(io, 4))[1]
            push!(meta, "magnification" => val)

            # alpha tilt angles

            push!(meta, "sdf" => [1, 2])
        end

        seek(io, 1024 + header_size)

        # read data
        proj_ = Array{dtype}(reinterpret(dtype, read(io, nx*ny*nz*sizeof(dtype))) )
        proj = reshape(proj_, Int(nx), Int(ny), Int(nz))

        println("for FEI conversion, we need to rotate 90 degree, but we didn't support yet.")
    end
    return proj, meta
end
