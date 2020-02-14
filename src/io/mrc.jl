"load mrc file"

# function load(io::Stream{format"MRC"})
#     print(io)
# end

"""
    load_mrc(fname::String, use_rotation=true)

# Args
- fname : input file name
- use_rotation : set true for ASTRA convention
"""
function load_mrc(fname::String, use_rotation=true; use_rad=true)

    meta = Dict{String, Any}()
    
    io = open(fname)

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
                 # alpha tilt angles
                if use_rad
                    ProjectionAngles[i] = deg2rad(ang)
                else
                    ProjectionAngles[i] = ang
                end
            end
            push!(meta, "ProjectionAngles" => ProjectionAngles)

            # pixel size
            seek(io, 1024+ 11*4)
            val = reinterpret(Float32, read(io, 4))[1]
            push!(meta, "pixelsize" => val*1e9)

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
        proj_ = reshape(proj_, Int(nx), Int(ny), Int(nz))
        proj_ = permutedims(proj_, [2, 1, 3])
        proj_ = proj_[end:-1:1, :, :]
        
        proj = zeros(nz, ny, nx)

        for z=1:nz
            if use_rotation
                proj[z, :, :] = rotr90(view(proj_, :, :, z) )
            else
                proj[z, :, :] = view(proj_, :, :, z) 
            end
        end
    close(io)
    return proj, meta
end


function load_ali(fname::String)
    return load_mrc(fname)
end