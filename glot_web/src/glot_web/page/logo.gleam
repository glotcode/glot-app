import glot_core/language.{type Language}
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/element/svg

pub fn language_logo(lang: Language) -> element.Element(msg) {
  case lang {
    language.Plaintext -> plaintext()
    language.Assembly -> assembly()
    language.Ats -> ats()
    language.Bash -> bash()
    language.C -> c()
    language.Clisp -> clisp()
    language.Clojure -> clojure()
    language.Cobol -> cobol()
    language.CoffeeScript -> coffeescript()
    language.Cpp -> cpp()
    language.Crystal -> crystal()
    language.Csharp -> csharp()
    language.D -> d()
    language.Dart -> dart()
    language.Elixir -> elixir()
    language.Elm -> elm()
    language.Erlang -> erlang()
    language.Fsharp -> fsharp()
    language.Go -> go()
    language.Groovy -> groovy()
    language.Guile -> guile()
    language.Hare -> hare()
    language.Haskell -> haskell()
    language.Idris -> idris()
    language.Java -> java()
    language.JavaScript -> javascript()
    language.Julia -> julia()
    language.Kotlin -> kotlin()
    language.Lua -> lua()
    language.Mercury -> mercury()
    language.Nim -> nim()
    language.Nix -> nix()
    language.Ocaml -> ocaml()
    language.Pascal -> pascal()
    language.Perl -> perl()
    language.Php -> php()
    language.Python -> python()
    language.Raku -> raku()
    language.Ruby -> ruby()
    language.Rust -> rust()
    language.Sac -> sac()
    language.Scala -> scala()
    language.Swift -> swift()
    language.TypeScript -> typescript()
    language.Zig -> zig()
  }
}

pub fn plaintext() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 24 24"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M6 2h8l4 4v16H6V2zm8 1.5V7h3.5M9 11h6M9 15h6M9 19h4",
        ),
        attribute.attribute("fill", "none"),
        attribute.attribute("stroke", "currentColor"),
        attribute.attribute("stroke-width", "1.5"),
      ]),
    ],
  )
}

pub fn assembly() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 1792 1792"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "m553 1399-50 50q-10 10-23 10t-23-10L-9 983q-10-10-10-23t10-23l466-466q10-10 23-10t23 10l50 50q10 10 10 23t-10 23L160 960l393 393q10 10 10 23t-10 23m591-1067L771 1623q-4 13-15.5 19.5T732 1645l-62-17q-13-4-19.5-15.5T648 1588l373-1291q4-13 15.5-19.5t23.5-2.5l62 17q13 4 19.5 15.5t2.5 24.5m657 651-466 466q-10 10-23 10t-23-10l-50-50q-10-10-10-23t10-23l393-393-393-393q-10-10-10-23t10-23l50-50q10-10 23-10t23 10l466 466q10 10 10 23t-10 23",
        ),
      ]),
    ],
  )
}

pub fn ats() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 400 400"),
      attribute.attribute("version", "1.0"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M81.5 100.4c-14.8 3.8-30.7 13.8-48.3 30.2l-8.4 7.7 11.3 11.3 11.3 11.3 5.5-5.2c9.6-9.1 20.8-17.4 28.5-21.3 6.6-3.2 8.2-3.6 13.3-3.2 6.9.5 10.1 2.5 13.5 8.3 3.3 5.7 6.8 14.4 7.4 18.7.6 3.5-1.3 6.7-43 71.8-24 37.4-43.6 68.4-43.6 68.9 0 .9 24.5 17.1 25.8 17.1.4 0 14-20.8 30.2-46.2s30.2-47.1 31.1-48.2c1.5-1.8 1.6-1 2.2 11 2.2 45.8 15.6 70 44.4 80.2l7.8 2.7 95.3.3 95.2.3V284l-93.7-.2-93.8-.3-4.1-2.2c-8.8-4.7-14-13.6-17-29.3-2-10-3.4-45.9-2.4-59 2.8-34.8-8.7-70.6-27-84.4-8.7-6.5-15.6-8.8-27-9.2-5.6-.2-11.5.2-14.5 1",
        ),
        attribute.attribute("fill", "red"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M180 125v20h67v16h-80v109h186V161h-80v-16h67v-40H180zm67 90.5V230h-54v-29h54zm80 0V230h-54v-29h54z",
        ),
        attribute.attribute("fill", "#00f"),
      ]),
    ],
  )
}

pub fn bash() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 512 512"),
      attribute.attribute("space", "preserve"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "m77.554 296.055 101.189-39.863v-.611L77.554 215.413v-44.464l154.539 68.379v32.807L77.554 340.514zm356.892 47.832v39.863H251.7v-39.863zM468.917.5H43.083C19.662.5.5 19.663.5 43.083v425.833c0 23.421 19.162 42.583 42.583 42.583h425.834c23.421 0 42.583-19.162 42.583-42.583V43.083C511.5 19.663 492.338.5 468.917.5m0 468.417H43.083V106.958h425.834z",
        ),
      ]),
    ],
  )
}

pub fn c() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 288"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M255.987 85.672c-.002-4.843-1.037-9.122-3.129-12.794-2.055-3.612-5.134-6.638-9.262-9.032-34.081-19.67-68.195-39.28-102.264-58.97-9.185-5.307-18.091-5.114-27.208.27-13.565 8.008-81.481 46.956-101.719 58.689C4.071 68.665.015 76.056.013 85.663 0 125.221.013 164.777 0 204.336c.002 4.736.993 8.932 2.993 12.55 2.056 3.72 5.177 6.83 9.401 9.278 20.239 11.733 88.164 50.678 101.726 58.688 9.121 5.387 18.027 5.579 27.215.27 34.07-19.691 68.186-39.3 102.272-58.97 4.224-2.447 7.345-5.559 9.401-9.276 1.997-3.618 2.99-7.814 2.992-12.551 0 0 0-79.094-.013-118.653",
        ),
        attribute.attribute("fill", "#A9B9CB"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M141.101 5.134c-9.17-5.294-18.061-5.101-27.163.269C100.395 13.39 32.59 52.237 12.385 63.94 4.064 68.757.015 76.129.013 85.711 0 125.166.013 164.62 0 204.076c.002 4.724.991 8.909 2.988 12.517 2.053 3.711 5.169 6.813 9.386 9.254a9009 9009 0 0 0 20.159 11.62L219.625 50.375c-26.178-15.074-52.363-30.136-78.524-45.241",
        ),
        attribute.attribute("fill", "#7F8B99"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m154.456 126.968 39.839.281c0-16.599-16.802-57.249-64.973-57.249-30.691 0-71.951 19.512-71.951 75.61S97.818 220 129.322 220c51.017 0 63.21-35.302 63.21-55.252l-38.007-2.173s1.017 23.075-25.406 23.075c-24.39 0-28.46-29.878-28.46-40.04 0-15.447 5.493-40.244 28.46-40.244 22.968 0 25.337 21.602 25.337 21.602",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
    ],
  )
}

pub fn clisp() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 512 512"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.circle([
        attribute.attribute("fill", "#fff"),
        attribute.attribute("r", "235"),
        attribute.attribute("cy", "256"),
        attribute.attribute("cx", "256"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M255.6 20a236 236 0 1 0 .8 472 236 236 0 0 0-.8-472zm2.2 1A235 235 0 0 1 422 422.3 117.5 117.5 0 0 1 256 256 119.4 119.4 0 0 0 115.5 66.4 234.2 234.2 0 0 1 257.8 21zM67 151.3h40c10 42.1 25.2 79.4 40.8 116.4A677.5 677.5 0 0 1 203 151.3h40c-49 97.3-102.2 164-24 250h-40c-47.6-77.3-82.4-147.7-112-250z",
        ),
        attribute.attribute("stroke-width", "5"),
        attribute.attribute("stroke", "#000"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M293 110.7c78.2 86 25 152.7-24 250h40c22-35.2 39.4-75 55.3-116.4 15.5 37 30.8 74.3 40.7 116.4h40c-29.6-102.3-64.4-172.7-112-250z",
        ),
      ]),
    ],
  )
}

pub fn clojure() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 100 99"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.circle([
        attribute.attribute("fill", "#fff"),
        attribute.attribute("r", "48.5"),
        attribute.attribute("cy", "49.5"),
        attribute.attribute("cx", "49.75"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M39.3 6.22c12.41-3.11 26.15-.58 36.53 6.94 12.85 8.94 20.29 25.06 18.6 40.64-.77 6.31-5.03 12.21-11.06 14.44-4.16 1.73-8.73 1.54-13.14 1.56 10.54-10.13 11.18-28.47 1.22-39.2-7.85-9.28-21.7-12.08-32.8-7.44-7.38-4.36-16.82-4.48-24.38-.47 6.38-7.9 15.05-14.13 25.03-16.47",
        ),
        attribute.attribute("fill", "#5881d8"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M42.93 26.99c5.56-1.49 11.62-1.37 16.86 1.15 8.92 4.05 14.82 14 13.62 23.8-.56 6.7-4.49 12.59-9.6 16.75-4.24-1.98-6.28-6.39-8.15-10.39-4.9-10.18-5.43-22.28-12.73-31.31",
        ),
        attribute.attribute("fill", "#90b4fe"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M12.3 33.3c4.81-4.81 12.03-6.4 18.61-5.24-5.69 5.43-9.47 12.97-9.45 20.93-.35 9.98 5.12 19.77 13.62 24.93 8.2 5.14 18.87 5.36 27.58 1.37 7.71 2.28 15.86 2.07 23.65.28C80.05 84 70.94 90.35 60.69 92.84c-12.67 3.19-26.69.4-37.13-7.47C12.16 77.09 5.12 63.11 5.44 49c-.29-5.94 2.78-11.58 6.86-15.7",
        ),
        attribute.attribute("fill", "#63b132"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M26.94 54c-1.97-8.94 2.26-18.41 9.51-23.76 5.54 3.47 7.78 9.9 10.1 15.67C43 53.4 38.44 60.46 35.94 68.42c-4.44-3.68-7.98-8.65-9-14.42M41.97 71.8c-.51-7.53 3.34-14.28 6.14-21 2.29 7.33 3.73 15.39 9.07 21.26-5.01 1.31-10.25 1.2-15.21-.26",
        ),
        attribute.attribute("fill", "#91dc47"),
      ]),
    ],
  )
}

pub fn cobol() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 512 512"),
      attribute.attribute("space", "preserve"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute("clip-rule", "evenodd"),
        attribute.attribute(
          "d",
          "M499.217 160.212s7.598-7.103 9.61-20.435c2.479-16.476.299-36.537.299-36.537s-5.106 15.204-13.132 24.839c-6.176 7.415-16.593 12.317-16.593 12.317s-31.908 3.082-48.792-3.955c-11.985-4.99-10.663-20.818-10.663-20.818s7.161-9.074 16.609-18.871c7.02-7.27 15.67-14.202 21.637-22.02 8.542-11.199 9.648-21.866 9.648-21.866s-27.813 13.657-49.961 29.139c-14.654 10.243-26.835 24.536-26.835 24.536l-4.13-6.604s12.347-13.128 15.728-28.436c3.627-16.443-1.688-35.148-1.688-35.148s-4.113 16.56-12.626 28.998C380.797 76.359 368.75 83.42 368.75 83.42s-6.088.978-9.527-2.911c-5.539-6.254-9.465-18.555-9.465-18.555s-6.383 4.171-12.13 1.946c-6.937-2.687-13.466-11.86-13.466-11.86s-8.067 5.988-18.189 8.413c-8.778 2.1-19.795.669-19.795.669s-3.692 5.473-12.517 8.142c-8.929 2.703-22.997 2.595-22.997 2.595s4.047 10.164-1.622 17.649c-5.893 7.785-21.496 12.908-21.496 12.908l14.043 14.035s-7.173 3.156-18.472 13.021c-8.6 7.51-17.187 18.988-25.188 26.764-7.689 7.477-14.971 11.411-14.971 11.411s-42.379 3.9-68.849 42.933c-20.946 30.902-9.598 80.102-9.598 80.102s-29.721 30.631-62.707 2.753c-37.585-31.771-14.913-80.373-14.913-80.373s-49.395 31.301-13.041 97.331c36.708 66.678 101.397 34.79 101.397 34.79l-3.306 15.687-6.604 8.259 3.302 7.431s1.955 9.739 1.713 17.388c-.154 4.957-2.537 9.032-2.537 9.032s-3.905 8.662-2.699 13.49c1.269 5.073 7.648 6.329 7.648 6.329s2.719 6.766 7.028 8.021c5.464 1.593 12.796-2.241 12.796-2.241s8.358 4.267 14.609 2.856c6.541-1.479 10.987-8.637 10.987-8.637s7.36.956 11.199-1.389c3.584-2.188 3.664-7.693 3.664-7.693l-17.341-15.687-.828-23.948s15.44-17.171 22.381-34.279c5.189-12.809 2.391-26.826 2.391-26.826s6.658-4.962 14.542-1.889c6.616 2.583 12.679 12.28 19.125 16.518 7.581 4.982 15.054 4.362 15.054 4.362s-1.206 9.682-.757 17.479c.37 6.541 2.408 11.424 2.408 11.424s5.656 4.017 8.658 10.209c3.497 7.215 4.807 17.195 11.182 24.132 4.508 4.907 10.151 4.583 14.697 7.19 7.231 4.146 12.529 9.664 12.529 9.664s6.209 9.028 6.209 19.683c0 7.373-6.521 14.389-8.01 20.863-1.605 6.974 1.801 13.129 1.801 13.129s6.916-.125 11.161 1.763c6.434 2.856 11.137 8.143 11.137 8.143s7.918-5.756 16.543-6.4c7.852-.595 16.484 3.926 16.484 3.926s5.56-.357 8.563-3.435c2.604-2.662 2.44-7.922 5.423-9.873 5.468-3.58 9.959-2.383 9.959-2.383s5.964-6.578 2.861-12.642c-2.212-4.316-8.6-6.088-12.555-9.889-5.099-4.907-7.644-11.324-7.644-11.324l9.083-10.732s7.36 3.68 13.474 4.52c5.854.812 10.471-1.218 10.471-1.218l.823-5.78s-12.234-21.259-14.072-51.242c-1.343-21.948 7.735-46.696 8.991-67.726 1.435-23.986-4.824-42.878-4.824-42.878s3.127-6.799 13.062-8.379c14.842-2.362 63.751 12.488 85.242 10.438 27.479-2.628 26.382-21.874 26.382-21.874s-8.155 4.591-17.142-.366c-11.033-6.076-23.317-21.932-23.317-21.932s11.369-6.524 29.912-.416c13.694 4.512 20.456 22.714 20.456 22.714s13.553-11.324 13.923-26.39c.454-18.1-12.267-42.153-12.267-42.153M303.188 357.144l-3.602-30.149 11.702-3.601 2.25 42.754z",
        ),
        attribute.attribute("fill-rule", "evenodd"),
      ]),
    ],
  )
}

pub fn coffeescript() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 206"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M101.614 9.071c.233 1.397-.466 2.562-2.794 3.726-3.027-1.63-9.548-2.562-14.903-2.096-5.822.466-10.712 2.329-10.013 6.287.931 3.959 6.52 6.288 16.533 5.356 24.45-2.096 24.217-18.629 60.078-21.889 27.943-2.561 43.544 6.055 45.64 16.533 1.63 8.15-5.123 16.068-25.382 17.698-17.93 1.63-28.409-3.26-29.34-8.15-.466-2.562.931-6.288 9.547-7.219.932 3.959 5.822 8.15 17.465 6.986 8.383-.699 15.368-3.726 14.437-8.383-.931-4.89-9.78-7.685-23.752-6.52-28.409 2.561-35.394 18.163-59.612 20.259C82.287 33.289 68.315 27 66.452 17.687c-.698-3.493-.698-11.643 17.465-13.273 9.314-.699 16.766.931 17.697 4.657m-90.815 97.336C2.882 116.42-.611 128.062.087 139.473c.699 11.41 6.287 20.724 15.136 27.943 9.314 7.218 19.327 9.314 30.738 7.218 4.424-.698 9.314-3.027 13.738-4.424-9.314 0-17.231-3.027-25.149-9.314-8.615-6.288-14.437-15.136-15.834-25.848-2.096-10.013 0-19.327 5.589-27.477 6.287-7.917 14.437-12.342 25.148-13.739 10.712-.698 20.026 2.096 29.34 8.616-2.095-3.027-5.122-5.123-7.916-7.917-9.315-6.288-19.328-9.315-31.67-6.288-11.177 2.33-20.491 8.15-28.408 18.164m124.813-53.791c-30.04 0-56.818-3.027-76.146-7.219-20.724-5.123-31.669-10.711-31.669-17.93 0-3.027 1.398-5.589 5.59-8.616-13.041 5.123-20.027 9.315-20.027 15.835.699 7.218 12.342 14.437 36.093 20.026 22.355 5.588 50.997 8.615 85.46 8.615 35.162 0 63.105-3.027 85.46-8.615 23.751-5.589 35.161-13.04 35.161-20.026 0-5.123-5.123-10.013-14.437-13.739 2.096 1.397 3.726 3.726 3.726 6.287 0 7.219-10.712 13.04-32.368 17.93-20.026 4.425-45.64 7.452-76.843 7.452m85.692 20.026c-22.355 5.123-50.996 8.616-85.46 8.616-35.161 0-63.803-3.726-86.158-8.616C29.66 67.519 18.95 61.93 15.223 56.109c3.726 25.149 12.342 48.9 23.752 69.858 8.616 13.04 17.231 24.45 25.847 36.792 3.726 7.218 6.287 14.437 7.917 21.656 5.589 7.917 13.74 13.04 23.752 15.834 12.342 4.424 25.149 6.287 38.19 5.589h1.396c13.04.698 26.78-1.398 39.354-5.589 9.314-3.027 17.231-7.917 23.053-15.834h.698c1.397-7.22 3.726-14.438 7.219-21.656 8.616-12.342 17.232-23.752 25.847-36.792 11.41-20.725 19.328-44.476 23.752-69.858-4.657 6.52-15.369 12.109-34.696 16.533",
        ),
        attribute.attribute("fill", "#28334C"),
      ]),
    ],
  )
}

pub fn cpp() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 288"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M255.569 84.72c-.002-4.83-1.035-9.098-3.124-12.761-2.052-3.602-5.125-6.621-9.247-9.008-34.025-19.619-68.083-39.178-102.097-58.817-9.17-5.294-18.061-5.101-27.163.269C100.395 12.39 32.59 51.237 12.385 62.94 4.064 67.757.015 75.129.013 84.711 0 124.166.013 163.62 0 203.076c.002 4.724.991 8.909 2.988 12.517 2.053 3.711 5.169 6.813 9.386 9.254 20.206 11.703 88.02 50.547 101.56 58.536 9.106 5.373 17.997 5.565 27.17.269 34.015-19.64 68.075-39.198 102.105-58.817 4.217-2.44 7.333-5.544 9.386-9.252 1.994-3.608 2.985-7.793 2.987-12.518 0 0 0-78.889-.013-118.345",
        ),
        attribute.attribute("fill", "#5C8DBC"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M128.182 143.509 2.988 215.593c2.053 3.711 5.169 6.813 9.386 9.254 20.206 11.703 88.02 50.547 101.56 58.536 9.106 5.373 17.997 5.565 27.17.269 34.015-19.64 68.075-39.198 102.105-58.817 4.217-2.44 7.333-5.544 9.386-9.252z",
        ),
        attribute.attribute("fill", "#1A4674"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M91.101 164.861c7.285 12.718 20.98 21.296 36.69 21.296 15.807 0 29.58-8.687 36.828-21.541l-36.437-21.107z",
        ),
        attribute.attribute("fill", "#1A4674"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M255.569 84.72c-.002-4.83-1.035-9.098-3.124-12.761l-124.263 71.55 124.413 72.074c1.994-3.608 2.985-7.793 2.987-12.518 0 0 0-78.889-.013-118.345",
        ),
        attribute.attribute("fill", "#1B598E"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M248.728 148.661h-9.722v9.724h-9.724v-9.724h-9.721v-9.721h9.721v-9.722h9.724v9.722h9.722zM213.253 148.661h-9.721v9.724h-9.722v-9.724h-9.722v-9.721h9.722v-9.722h9.722v9.722h9.721z",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M164.619 164.616c-7.248 12.854-21.021 21.541-36.828 21.541-15.71 0-29.405-8.578-36.69-21.296a42.06 42.06 0 0 1-5.574-20.968c0-23.341 18.923-42.263 42.264-42.263 15.609 0 29.232 8.471 36.553 21.059l36.941-21.272c-14.683-25.346-42.096-42.398-73.494-42.398-46.876 0-84.875 38-84.875 84.874 0 15.378 4.091 29.799 11.241 42.238 14.646 25.48 42.137 42.637 73.634 42.637 31.555 0 59.089-17.226 73.714-42.781z",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
    ],
  )
}

pub fn crystal() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "-134 328.3 99.409 99.1"),
      attribute.attribute("space", "preserve"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute("transform", "translate(-19.2 -19.3)"),
        attribute.attribute("style", "fill:#010101"),
        attribute.attribute(
          "d",
          "m-15.6 410.7-36 35.9c-.1.1-.3.1-.6.1l-49.1-13.1c-.1 0-.3-.1-.4-.4l-13.1-49c0-.1 0-.4.1-.6l36-35.9c.1-.1.3-.1.6-.1l49.1 13.2c.1 0 .3.1.4.4l13.1 49c.2.2.1.4-.1.5m-48.1-39-48.2 13q-.15 0 0 .3l35.3 35.3c.1.1.1 0 .3 0l13-48.1c-.2-.5-.4-.5-.4-.5",
        ),
      ]),
    ],
  )
}

pub fn csharp() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 512 512"),
      attribute.attribute("space", "preserve"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "m233.274 286.089 89.802 27.145q-9.053 37.781-28.5 63.107c-12.975 16.894-29.071 29.638-48.297 38.233q-28.841 12.894-73.412 12.894-54.058 0-88.33-15.711c-22.852-10.477-42.563-28.896-59.155-55.271Q.5 316.927.5 255.208c0-54.855 14.594-97.016 43.769-126.479 29.18-29.461 70.464-44.197 123.855-44.197 41.776 0 74.614 8.451 98.51 25.336 23.91 16.892 41.659 42.834 53.273 77.816l-90.481 20.131c-3.164-10.098-6.485-17.492-9.95-22.168q-8.598-11.759-21.043-18.095c-8.294-4.22-17.564-6.337-27.82-6.337-23.23 0-41.024 9.343-53.391 28.021-9.342 13.861-14.018 35.626-14.018 65.294q-.001 55.132 16.732 75.584 16.741 20.44 47.059 20.439 29.397.002 44.449-16.516c10.03-10.997 17.307-26.991 21.83-47.948m252.071-46.83-6.854 34.292H511.5v37.262h-40.452l-9.5 47.522h-38.41l9.527-47.522h-29.769l-9.595 47.522h-38.14l9.527-47.522h-18.572v-37.262h26.047l6.876-34.292h-32.923v-37.262h40.398l9.688-48.332h38.409l-9.752 48.332h29.625l9.694-48.332h38.273l-9.657 48.332H511.5v37.262zm-38.328 0h-29.68l-6.921 34.292h29.724z",
        ),
      ]),
    ],
  )
}

pub fn d() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("version", "1.0"),
      attribute.attribute("viewBox", "0 0 123.865 93.753"),
      attribute.attribute("xlink", "http://www.w3.org/1999/xlink"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.defs([], [
        svg.linear_gradient([attribute.id("dGradientB")], [
          svg.stop([
            attribute.attribute("style", "stop-color:#fff;stop-opacity:1"),
            attribute.attribute("offset", "0"),
          ]),
          svg.stop([
            attribute.attribute(
              "style",
              "stop-color:#fff;stop-opacity:.33333334",
            ),
            attribute.attribute("offset", "1"),
          ]),
        ]),
        svg.linear_gradient([attribute.id("dGradientA")], [
          svg.stop([
            attribute.attribute(
              "style",
              "stop-color:#f2f2f0;stop-opacity:.13541667",
            ),
            attribute.attribute("offset", "0"),
          ]),
          svg.stop([
            attribute.attribute(
              "style",
              "stop-color:#eeeeec;stop-opacity:.39583334",
            ),
            attribute.attribute("offset", "1"),
          ]),
        ]),
        svg.linear_gradient(
          [
            attribute.attribute("spreadMethod", "reflect"),
            attribute.attribute("gradientUnits", "userSpaceOnUse"),
            attribute.attribute(
              "gradientTransform",
              "matrix(1 0 0 .99176 -.678 .501)",
            ),
            attribute.attribute("y2", "47.031"),
            attribute.attribute("y1", "33.563"),
            attribute.attribute("x2", "44.496"),
            attribute.attribute("x1", "27.248"),
            attribute.href("#dGradientA"),
            attribute.id("dGradientD"),
          ],
          [],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("gradientUnits", "userSpaceOnUse"),
            attribute.attribute(
              "gradientTransform",
              "matrix(.99719 0 0 .98872 -.497 .687)",
            ),
            attribute.attribute("y2", "90.719"),
            attribute.attribute("y1", "30.994"),
            attribute.attribute("x2", "104.024"),
            attribute.attribute("x1", "24.482"),
            attribute.href("#dGradientB"),
            attribute.id("dGradientE"),
          ],
          [],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("spreadMethod", "reflect"),
            attribute.attribute("gradientUnits", "userSpaceOnUse"),
            attribute.attribute(
              "gradientTransform",
              "matrix(1 0 0 -.99176 -.678 121.014)",
            ),
            attribute.attribute("y2", "47.031"),
            attribute.attribute("y1", "33.563"),
            attribute.attribute("x2", "44.496"),
            attribute.attribute("x1", "27.248"),
            attribute.href("#dGradientA"),
            attribute.id("dGradientF"),
          ],
          [],
        ),
      ]),
      svg.g(
        [
          attribute.attribute(
            "transform",
            "translate(-33.347 -44.392)scale(1.47509)",
          ),
          attribute.attribute("style", "display:inline"),
        ],
        [
          svg.rect([
            attribute.attribute(
              "style",
              "fill:#2e3436;fill-opacity:.2745098;fill-rule:nonzero;stroke:none",
            ),
            attribute.attribute("ry", "8.543"),
            attribute.attribute("rx", "7.694"),
            attribute.attribute("y", "33.484"),
            attribute.attribute("x", "25.996"),
            attribute.attribute("height", "60.168"),
            attribute.attribute("width", "80.582"),
          ]),
          svg.rect([
            attribute.attribute(
              "style",
              "fill:#a40000;fill-opacity:1;fill-rule:nonzero;stroke:none",
            ),
            attribute.attribute("ry", "8.543"),
            attribute.attribute("rx", "7.694"),
            attribute.attribute("y", "30.772"),
            attribute.attribute("x", "23.285"),
            attribute.attribute("height", "60.168"),
            attribute.attribute("width", "80.582"),
          ]),
          svg.rect([
            attribute.attribute(
              "style",
              "fill:url(#dGradientD);fill-opacity:1;fill-rule:nonzero;stroke:none",
            ),
            attribute.attribute("ry", "5.62"),
            attribute.attribute("rx", "5.221"),
            attribute.attribute("y", "33.787"),
            attribute.attribute("x", "26.57"),
            attribute.attribute("height", "54.138"),
            attribute.attribute("width", "74.011"),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "font-size:64px;font-style:normal;font-variant:normal;font-weight:400;font-stretch:normal;text-align:start;line-height:125%;writing-mode:lr-tb;text-anchor:start;fill:#eeeeec;fill-opacity:1;stroke:none;font-family:Gill Sans MT",
            ),
            attribute.attribute(
              "d",
              "M32.333 39.188c-.81.1-1.445.747-1.448 1.53l.051 39.977a2 2 0 0 0 0 .174 1.3 1.3 0 0 0 0 .27v.04c.01.037.03.077.042.115v.02c.01.038.01.078.021.115v.04q.03.058.063.115v.02c.028.039.071.079.103.115v.02q.03.058.063.116v.038c.04.03.082.05.124.077v.04c.03.029.051.049.083.076l.042.039c.03.03.05.05.083.077h.02q.116.097.25.174h.04q.061.03.125.058h.02q.062.03.125.057c.06.013.125.013.187.02.1.018.208.037.31.038h.166l15.31-.062c4.376-.007 7.307-.082 9.053-.303h.041c1.67-.232 3.44-.66 5.364-1.284 3.345-1.046 6.311-2.591 8.861-4.655 2.497-2 4.432-4.366 5.792-7.029s2.046-5.478 2.04-8.397c-.007-4.062-1.236-7.867-3.702-11.289-2.466-3.423-5.832-6.044-9.974-7.78-4.212-1.785-9.703-2.599-16.515-2.586l-16.533.024c-.07 0-.138-.008-.207 0m8.898 8.226 7.127-.01c3.33-.006 5.7.095 7.044.28 1.363.187 2.855.582 4.435 1.192 1.567.597 2.932 1.328 4.105 2.238v.038c3.228 2.471 4.75 5.441 4.756 9.373.007 4.027-1.463 7.163-4.607 9.793a15.3 15.3 0 0 1-3.23 2.036c-1.12.522-2.584.972-4.431 1.36-1.742.349-4.387.547-7.83.553l-7.334.01z",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "transform",
              "matrix(1.95002 0 0 1.95002 -82.918 -16.343)",
            ),
            attribute.attribute(
              "style",
              "fill:#eeeeec;fill-opacity:1;fill-rule:nonzero;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M89.368 35.648a5.969 5.472 0 1 1-11.938 0 5.969 5.472 0 1 1 11.938 0",
            ),
          ]),
          svg.rect([
            attribute.attribute(
              "style",
              "fill:none;stroke:url(#dGradientE);stroke-width:1.34628034;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none",
            ),
            attribute.attribute("ry", "7.306"),
            attribute.attribute("rx", "6.57"),
            attribute.attribute("y", "31.981"),
            attribute.attribute("x", "24.572"),
            attribute.attribute("height", "57.75"),
            attribute.attribute("width", "78.006"),
          ]),
          svg.rect([
            attribute.attribute(
              "style",
              "fill:none;stroke:#323232;stroke-width:1.3558476;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none",
            ),
            attribute.attribute("ry", "8.543"),
            attribute.attribute("rx", "7.694"),
            attribute.attribute("y", "30.772"),
            attribute.attribute("x", "23.285"),
            attribute.attribute("height", "60.168"),
            attribute.attribute("width", "80.582"),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:url(#dGradientF);fill-opacity:1;fill-rule:nonzero;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M31.791 87.728H95.36c2.892 0 5.22-2.506 5.22-5.62v-9.001c-22.704-8.734-55.576-13.412-74.01-13.559v22.56c0 3.114 2.329 5.62 5.221 5.62",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "transform",
              "matrix(.62657 0 0 .62657 40.72 19.11)",
            ),
            attribute.attribute(
              "style",
              "fill:#eeeeec;fill-opacity:1;fill-rule:nonzero;stroke:none;display:inline",
            ),
            attribute.attribute(
              "d",
              "M89.368 35.648a5.969 5.472 0 1 1-11.938 0 5.969 5.472 0 1 1 11.938 0",
            ),
          ]),
        ],
      ),
    ],
  )
}

pub fn dart() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 502.87 502.87"),
      attribute.attribute("data-name", "Layer 1"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute.id("Layer_1"),
    ],
    [
      svg.defs([], [
        svg.radial_gradient(
          [
            attribute.attribute("gradientUnits", "userSpaceOnUse"),
            attribute.attribute("gradientTransform", "translate(0 -380.56)"),
            attribute.attribute("r", "251.4"),
            attribute.attribute("cy", "631.97"),
            attribute.attribute("cx", "251.42"),
            attribute.id("radial-gradient"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-opacity", ".1"),
              attribute.attribute("stop-color", "#fff"),
              attribute.attribute("offset", "0"),
            ]),
            svg.stop([
              attribute.attribute("stop-opacity", "0"),
              attribute.attribute("stop-color", "#fff"),
              attribute.attribute("offset", "1"),
            ]),
          ],
        ),
        element.element("style", [], [
          html.text(
            ".cls-1{fill:#01579b}.cls-2{fill:#40c4ff}.cls-4{fill:#fff;opacity:.2;isolation:isolate}",
          ),
        ]),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m102.56 400.31-86-86C6.32 303.82 0 289 0 274.58c0-6.69 3.77-17.16 6.62-23.15L86 86Z",
        ),
        attribute.class("cls-1"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m397 102.56-86-86C303.49 9 287.85 0 274.61 0c-11.38 0-22.55 2.29-29.76 6.62L86.07 86ZM205.11 502.87h208.44v-89.32l-155.5-49.65-142.26 49.65z",
        ),
        attribute.class("cls-2"),
      ]),
      svg.path([
        attribute.attribute("style", "fill:#29b6f6"),
        attribute.attribute(
          "d",
          "M86 354c0 26.54 3.33 33.05 16.53 46.32l13.23 13.24h297.79L268 248.14 86 86Z",
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M350.7 86H86l327.55 327.51h89.32V208.4L397 102.52C382.12 87.62 368.92 86 350.7 86",
        ),
        attribute.class("cls-1"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M105.88 403.6c-13.23-13.27-16.52-26.36-16.52-49.6V89.32L86.07 86v268c0 23.25 0 29.69 19.81 49.61l9.91 9.91Z",
        ),
        attribute.class("cls-4"),
      ]),
      svg.path([
        attribute.attribute(
          "style",
          "opacity:.2;isolation:isolate;fill:#263238",
        ),
        attribute.attribute(
          "d",
          "M499.58 205.11v205.11h-89.32l3.29 3.33h89.32V208.4z",
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M397 102.56C380.61 86.14 367.19 86 347.41 86H86.07l3.29 3.29h258.05c9.87 0 34.79-1.66 49.61 13.24Z",
        ),
        attribute.class("cls-4"),
      ]),
      svg.path([
        attribute.attribute(
          "style",
          "opacity:.2;isolation:isolate;fill:url(#radial-gradient)",
        ),
        attribute.attribute(
          "d",
          "M499.58 205.11 397 102.56l-86-86C303.49 9 287.85 0 274.61 0c-11.38 0-22.55 2.29-29.76 6.62L86.07 86 6.65 251.43C3.81 257.46 0 267.92 0 274.58c0 14.45 6.36 29.2 16.52 39.7L95.83 393a92 92 0 0 0 6.73 7.32l3.29 3.29 9.9 9.91 86 86 3.29 3.29h208.4v-89.3h89.32V208.4Z",
        ),
      ]),
    ],
  )
}

pub fn elixir() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 100 100"),
      attribute.attribute("space", "preserve"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M57.221 24.648c7.321 15.719 26.377 22.286 24.654 42.742-2.029 24.092-19.164 30.145-28.638 30.576s-27.561-2.907-32.514-25.623C15.161 46.828 39.456 7.638 53.452 2.039c-.538 6.352.819 16.277 3.769 22.609M44.761 89.69c6.407 1.331 11.317 2.256 11.899-.324.877-3.884-14.063-6.075-24.049-7.156 2.997 3.162 9.048 6.835 12.15 7.48",
        ),
      ]),
    ],
  )
}

pub fn elm() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 323.141 322.95"),
      attribute.attribute("space", "preserve"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.g([attribute.attribute("fill", "#34495E")], [
        svg.path([
          attribute.attribute(
            "d",
            "m161.649 152.782 69.865-69.866H91.783zM8.867 0l70.374 70.375h152.972L161.838 0zM246.999 85.162l76.138 76.137-76.485 76.485-76.138-76.138zM323.298 143.724V0H179.573zM152.781 161.649 0 8.868v305.564zM255.522 246.655l67.776 67.777V178.879zM161.649 170.517 8.869 323.298H314.43z",
          ),
        ]),
      ]),
    ],
  )
}

pub fn erlang() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 225"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute("d", "M0 0h256v225H0z"),
        attribute.attribute("fill", "#FFF"),
      ]),
      svg.g([attribute.attribute("fill", "#A90533")], [
        svg.path([
          attribute.attribute(
            "d",
            "M44.34 159.66c-18.803-19.926-29.805-47.452-29.777-80.295-.026-29.045 9.1-54.01 24.789-73.008l-.026.01H6.351v153.295h37.966zM218.01 159.672c8.1-8.676 15.357-18.893 21.934-30.578l-36.499-18.25c-12.818 20.84-31.564 40.022-57.486 40.15-37.726-.128-52.549-32.388-52.467-73.91h140.977c.189-4.689.189-6.868 0-9.125.92-24.703-5.627-45.468-17.536-61.638l-.062.046h31.742v153.296H217.94z",
          ),
        ]),
        svg.path([
          attribute.attribute(
            "d",
            "M95.774 41.497c1.56-18.8 16.383-31.443 33.761-31.48 17.498.037 30.14 12.68 30.568 31.48z",
          ),
        ]),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M26.426 185.668v-6.387H6.807v37.868h19.619v-6.388H14.107v-10.037H25.97v-6.387H14.107v-8.67zM59.731 201.18c4.89-.726 7.576-5.573 7.756-10.494-.18-8.05-5.399-11.381-12.775-11.406H44.675v37.868h7.3v-15.056l9.125 15.056h9.124zm-7.757-15.968h.913c3.982.15 6.971 1.058 6.843 5.931.128 4.465-2.76 5.677-6.843 5.475h-.913zM93.036 179.281h-7.3v37.868h17.793v-6.388H93.036zM140.94 209.392l3.194 7.756h7.756l-14.143-38.78h-5.931l-15.056 38.78h7.755l3.195-7.756zm-1.824-5.93h-9.125l4.106-14.144zM165.578 217.149h7.756v-25.55l20.075 26.462h5.474v-38.78h-7.756v25.55l-20.075-26.463h-5.474zM230.82 197.074v5.93h8.212c-.17 4.767-4.072 8.806-8.668 8.67-7.26.136-10.857-6.88-10.95-13.232.093-6.266 3.64-13.585 10.95-13.687 3.836.101 7.08 2.726 8.668 5.931l6.388-3.193c-2.81-5.917-8.484-9.199-15.056-9.125-11.313-.073-18.558 9.265-18.706 20.074.148 10.54 7.191 19.93 18.25 20.075 11.943-.146 17.465-9.686 17.337-20.53v-.913z",
        ),
      ]),
    ],
  )
}

pub fn fsharp() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 128 128"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute("style", "fill:#378bba"),
        attribute.attribute("d", "M5 63 61 7v28L33 63l28 28v28z"),
      ]),
      svg.path([
        attribute.attribute("style", "fill:#378bba"),
        attribute.attribute("d", "m41 63 20-20v40z"),
      ]),
      svg.path([
        attribute.attribute("style", "fill:#30b9db"),
        attribute.attribute("d", "M123 63 65 7v28l28 28-28 28v28z"),
      ]),
    ],
  )
}

pub fn go() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 254.5 225"),
      attribute.attribute("version", "1.1"),
      attribute.attribute("y", "0"),
      attribute.attribute("x", "0"),
      attribute.attribute("space", "preserve"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute.id("Layer_1"),
    ],
    [
      element.element("style", [], [html.text(".st0{fill:#2dbcaf}")]),
      svg.path([
        attribute.attribute(
          "d",
          "M40.2 101.1c-.4 0-.5-.2-.3-.5l2.1-2.7c.2-.3.7-.5 1.1-.5h35.7c.4 0 .5.3.3.6l-1.7 2.6c-.2.3-.7.6-1 .6zM25.1 110.3c-.4 0-.5-.2-.3-.5l2.1-2.7c.2-.3.7-.5 1.1-.5h45.6c.4 0 .6.3.5.6l-.8 2.4c-.1.4-.5.6-.9.6zM49.3 119.5c-.4 0-.5-.3-.3-.6l1.4-2.5c.2-.3.6-.6 1-.6h20c.4 0 .6.3.6.7l-.2 2.4c0 .4-.4.7-.7.7z",
        ),
        attribute.class("st0"),
      ]),
      svg.g([attribute.id("CXHf1q_1_")], [
        svg.path([
          attribute.attribute(
            "d",
            "M153.1 99.3c-6.3 1.6-10.6 2.8-16.8 4.4-1.5.4-1.6.5-2.9-1-1.5-1.7-2.6-2.8-4.7-3.8-6.3-3.1-12.4-2.2-18.1 1.5-6.8 4.4-10.3 10.9-10.2 19 .1 8 5.6 14.6 13.5 15.7 6.8.9 12.5-1.5 17-6.6.9-1.1 1.7-2.3 2.7-3.7h-19.3c-2.1 0-2.6-1.3-1.9-3 1.3-3.1 3.7-8.3 5.1-10.9.3-.6 1-1.6 2.5-1.6h36.4c-.2 2.7-.2 5.4-.6 8.1-1.1 7.2-3.8 13.8-8.2 19.6-7.2 9.5-16.6 15.4-28.5 17-9.8 1.3-18.9-.6-26.9-6.6-7.4-5.6-11.6-13-12.7-22.2-1.3-10.9 1.9-20.7 8.5-29.3 7.1-9.3 16.5-15.2 28-17.3 9.4-1.7 18.4-.6 26.5 4.9 5.3 3.5 9.1 8.3 11.6 14.1.6.9.2 1.4-1 1.7",
          ),
          attribute.class("st0"),
        ]),
        svg.path([
          attribute.attribute(
            "d",
            "M186.2 154.6c-9.1-.2-17.4-2.8-24.4-8.8-5.9-5.1-9.6-11.6-10.8-19.3-1.8-11.3 1.3-21.3 8.1-30.2 7.3-9.6 16.1-14.6 28-16.7 10.2-1.8 19.8-.8 28.5 5.1 7.9 5.4 12.8 12.7 14.1 22.3 1.7 13.5-2.2 24.5-11.5 33.9-6.6 6.7-14.7 10.9-24 12.8-2.7.5-5.4.6-8 .9m23.8-40.4c-.1-1.3-.1-2.3-.3-3.3-1.8-9.9-10.9-15.5-20.4-13.3-9.3 2.1-15.3 8-17.5 17.4-1.8 7.8 2 15.7 9.2 18.9 5.5 2.4 11 2.1 16.3-.6 7.9-4.1 12.2-10.5 12.7-19.1",
          ),
          attribute.class("st0"),
        ]),
      ]),
    ],
  )
}

pub fn groovy() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 614.061 305.599"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute("transform", "translate(-35.397 -30.558)"),
        attribute.attribute("style", "fill:#333;fill-opacity:1"),
        attribute.attribute(
          "d",
          "M154.977 332.692c0-.806 10.831-18.622 24.07-39.591 13.237-20.97 22.66-38.62 20.938-39.226-1.722-.605-7.68.486-13.24 2.424-16.745 5.837-20.186 4.29-32.693-14.702-13.533-20.549-14.017-22.67-6.962-30.466 4.609-5.092 4.332-6.28-3.232-13.843-4.55-4.55-8.273-9.643-8.273-11.318 0-2.816-30.991-15.589-79.989-32.966-11.11-3.94-20.2-7.83-20.2-8.643s23.471-1.005 52.158-.424l52.157 1.054 5.091-8.03c21.517-33.936 54.01-64.588 68.467-64.588 3.01 0 9.122 2.87 13.58 6.376 7.26 5.71 8.256 9.249 9.55 33.892.794 15.134 2.424 28.496 3.622 29.694 1.198 1.197 4.997-.375 8.444-3.494 4.401-3.983 9.035-5.063 15.568-3.628 6.767 1.486 10.627.469 14.17-3.735 5.313-6.307 31.905-48.938 31.905-51.15 0-.75 5.265-9.756 11.7-20.012s13.847-22.08 16.47-26.278c4.666-7.465 5.397-6.582 33.427 40.399 28.941 48.507 44.518 66.406 52.316 60.117 5.442-4.389 34-4.638 41.982-.366 4.537 2.428 7.42 2.396 9.925-.11 5.2-5.2 17.65-4.294 20.904 1.521 2.564 4.582 3.218 4.582 7.02 0 2.307-2.778 9.137-5.052 15.179-5.052 8.538 0 11.793 1.774 14.614 7.965l3.628 7.964 56.092-1.986c30.851-1.092 56.092-1.287 56.092-.432 0 .854-22.906 10.071-50.902 20.483s-51.367 19.243-51.935 19.625.699 9.493 2.814 20.246c5.505 27.98 1.915 46.626-11.926 61.946-6.209 6.873-16.283 14.144-22.388 16.159-6.104 2.014-11.098 4.386-11.098 5.27s6.515 11.679 14.478 23.989 13.283 22.38 11.822 22.38c-2.385 0-60.47-22.442-150.79-58.26-17.808-7.062-34.026-12.841-36.039-12.841-3.753 0-36.167 12.287-131.224 49.742-55.125 21.721-57.292 22.474-57.292 19.895m113.116-51.253c29.33-11.395 58.417-22.53 64.638-24.746 10.701-3.81 14.28-2.855 66.254 17.686 30.219 11.943 60.033 23.576 66.254 25.852s19.043 7.22 28.493 10.989c10.775 4.297 16.282 5.331 14.771 2.774-16.884-28.56-17.4-29.037-29.1-26.842-14.114 2.648-22.88-.068-27.385-8.485-2.92-5.458-2.029-8.128 5.255-15.73 10.849-11.324 9.144-21.742-4.844-29.611-5.368-3.02-12.141-10.484-15.051-16.587l-5.292-11.097-11.346 7.7c-13.944 9.462-30.95 9.95-45.147 1.294l-10.465-6.381-12.159 8.263c-12.174 8.274-26.19 9.343-40.437 3.084-3.925-1.725-5.656-1.054-5.656 2.19 0 2.57-3.704 6.362-8.232 8.425-13.574 6.185-26.82 4.543-35.802-4.438l-8.19-8.19-6.61 8.403c-3.635 4.622-12.049 11.837-18.697 16.034-8.23 5.195-18.418 17.872-31.917 39.714-10.905 17.645-19.828 32.98-19.828 34.077s8.363-1.527 18.584-5.832 42.58-17.151 71.91-28.546m248.768-12.258c22.255-12.509 27.414-35.649 17.576-78.844-8.22-36.1-12.325-47.913-17.194-49.496-3.37-1.095-3.887.107-1.989 4.617 12.315 29.257 13 43.946 2.24 48.075-7.391 2.837-15.232-7.79-21.399-29.003-4.775-16.426-9.768-23.829-13.534-20.063-.901.901.679 6.12 3.512 11.599 2.832 5.478 6.717 21.974 8.632 36.66 1.915 14.684 5.614 30.06 8.22 34.168 6.771 10.677 17.55 8.104 24.523-5.854 6.894-13.8 7.673-4.607.97 11.436-6.961 16.66-27.635 21.655-51.585 12.465-3.833-1.471-5.13.051-5.13 6.02 0 4.395-2.936 11.723-6.525 16.285l-6.525 8.296 8.949 1.51c15.45 2.61 36.633-.776 49.259-7.871m-320.367-27.538c46.46-13.354 54.762-28.93 39.329-73.788-3.582-10.41-6.512-21.61-6.512-24.886 0-11.157-5.612-6.002-9.818 9.02-5.562 19.865-22.29 36.75-36.345 36.683-12.205-.058-16.182-2.28-21.224-11.858-9.047-17.189.815-43.568 25.97-69.463 18.424-18.966 28.489-20.683 28.489-4.862 0 24.674-17.011 60.995-25.973 55.456-4.382-2.708-3.672-14.667 1.417-23.85 4.327-7.808 3.448-19.707-1.456-19.707-5.687 0-16.946 20.712-18.433 33.91-1.315 11.669-.493 14.506 5.066 17.481 19.483 10.427 45.006-21.395 46.291-57.716.675-19.073-3.017-24.44-14.779-21.489-17.119 4.297-63.235 63.787-63.235 81.574 0 13.913 6.988 23.697 19.288 27.01 20.915 5.631 41.136-4.374 55.464-27.444l6.021-9.696.014 13.173c.016 19.073-12.426 29.127-51.698 41.767-9.777 3.147-18.184 6.055-18.682 6.462-1.82 1.486 16.687 27.476 19.566 27.476 1.633 0 11.191-2.364 21.241-5.253zm279.917-23.68c4.663-5.153 5.486-10.751 4.486-30.548-1.088-21.534-2.278-25.339-10.662-34.09-15.148-15.812-33.86-11.778-22.908 4.938 5.823 8.887 12.926 7.37 10.417-2.225-2-7.643 1.73-7.844 8.228-.444 12.193 13.886 9.115 33.127-5.299 33.127-9.867 0-12.942-4.231-19.373-26.663-2.93-10.22-6.5-18.583-7.931-18.583-4.77 0-6.893 4.209-3.928 7.782 1.611 1.941 6.073 15.891 9.914 31 9.67 38.027 23.177 51.042 37.056 35.706m-183.771.604c1.99-1.335 2.9-7.649 2.078-14.423-1.324-10.927-2.066-11.724-7.972-8.563-8.488 4.542-17.609-4.064-20.703-19.533-2.347-11.735-3.065-11.505 14.026-4.501 2.143.878 7.597-2.104 12.12-6.627 8.274-8.274 10.998-18.213 4.991-18.213a3.24 3.24 0 0 0-3.231 3.232c0 4.649-8.843 3.99-10.835-.808-1.162-2.8-3.638-1.806-8.06 3.232-3.51 3.999-7.796 7.271-9.526 7.271s-4.065-3.272-5.19-7.271c-1.973-7.01-2.214-7.053-6.678-1.222-3.91 5.108-3.946 6.736-.225 10.456 3.941 3.941 11.427 30.871 11.427 41.108 0 12.729 17.529 22.738 27.778 15.862zm58.943-16.875a42.22 42.22 0 0 0 9.13-46.184c-5.17-12.374-14.145-17.005-26.8-13.83-9.402 2.36-23.723 29.777-23.773 45.516-.08 24.53 23.25 32.69 41.443 14.498m-22.084-19.434c-3.555-3.556-6.417-10.464-6.36-15.352.093-8.08.493-8.373 4.396-3.232 4.824 6.356 13.398 7.457 16.682 2.142 1.194-1.932.553-5.132-1.425-7.11-5.082-5.081-4.466-12 1.068-12 6.151 0 14.727 12.515 14.727 21.493 0 6.606-13.445 20.522-19.828 20.522-1.538 0-5.704-2.908-9.26-6.463m86.35 18.583c13.41-14.603 12.103-37.098-3.099-53.326-7.85-8.381-25.293-9.826-32.432-2.687-6.587 6.588-13.164 32.493-10.72 42.228 5.21 20.764 32.4 28.867 46.25 13.785m-27.456-23.615c-5.306-3.716-7.13-8.15-6.978-16.967.169-9.86.684-10.75 2.961-5.114 3.346 8.28 10.363 11.407 16.518 7.36 3.818-2.509 3.64-3.695-1.1-7.328-6.323-4.846-7.556-11.702-2.105-11.702 4.873 0 22.304 19.066 22.304 24.398 0 5.203-12.378 14.385-19.392 14.385-2.764 0-8.258-2.264-12.208-5.032m189.963-14.288L612.29 150.2l-36.36-.131c-32.538-.118-36.354.463-36.314 5.524.04 5.128 3.33 20.284 4.373 20.14.237-.033 15.701-5.791 34.366-12.797zm-443.494-2.28 3.468-10.287-30.466-1.024c-16.757-.564-30.464-.132-30.46.958.006 1.595 52.507 22.107 53.662 20.965.18-.178 1.889-4.954 3.796-10.612m208.91-31.887c7.166 1.146 15.25 4.08 17.962 6.519 4.213 3.788 6.045 3.53 12.562-1.77 4.196-3.413 9.65-6.205 12.12-6.205s4.49-.713 4.49-1.584c0-3.01-46.54-79.213-48.315-79.11-2.085.12-49.786 80.088-51.255 85.924-.616 2.45 1.318 3.354 5.074 2.372 3.338-.873 7.954.683 10.257 3.458 3.736 4.501 5.261 4.143 14.131-3.32 8.426-7.091 11.93-8.05 22.973-6.284",
        ),
      ]),
      svg.path([
        attribute.attribute("transform", "translate(-35.397 -30.558)"),
        attribute.attribute("style", "fill:#6398aa;fill-opacity:1;stroke:none"),
        attribute.attribute(
          "d",
          "M309.546 140.88c-.501-.234-1.118-.769-2.528-2.191-1.912-1.93-2.672-2.49-4.261-3.146-2.088-.862-4.355-1.095-6.482-.664-1.898.384-2.425.425-3.283.257-1.432-.279-1.941-1.149-1.536-2.622.506-1.837 4.337-8.943 12.01-22.274 15.583-27.08 36.536-61.221 38.85-63.307.256-.23.265-.23.522 0 1.378 1.236 9.477 13.726 20.54 31.679 14.968 24.285 27.412 45.643 27.412 47.047 0 .858-1.316 1.372-4.086 1.599-3.442.28-7.425 2.302-12.869 6.529-2.587 2.009-3.691 2.76-4.95 3.364-1.05.505-1.138.525-2.27.525-1.113 0-1.226-.025-2.095-.461-.513-.258-1.505-.95-2.242-1.564-2.178-1.816-4.8-3.136-9.072-4.571-5.43-1.824-11.244-2.919-16.195-3.05-3.91-.102-5.712.249-8.676 1.69-2.42 1.178-3.587 2.014-9.125 6.542-5.634 4.606-7.635 5.562-9.664 4.617M128.638 170.739c-10.16-2.96-45.503-16.92-50.451-19.925-.683-.415-.738-.478-.543-.62 1.131-.828 12.338-1.24 25.004-.919 5.051.128 35.501 1.133 35.55 1.174.1.081-6.521 19.289-7.03 20.394-.212.462-.65.444-2.53-.104M543.694 175.31c-1.386-2.712-3.888-14.97-3.96-19.408-.03-1.724.186-2.427.96-3.14 1.774-1.636 5.38-2.224 15.29-2.495 5.004-.137 28.102-.158 44.411-.04l11.429.082-27.518 10.314c-25.093 9.405-39.684 14.841-40.225 14.985-.135.036-.27-.068-.387-.297M178.088 315.514c0-.77 3.27-6.533 11.554-20.367 19.851-33.146 28.927-45.16 40.073-53.044 9.971-7.053 15.303-11.93 21.246-19.43l3.664-4.625 4.94 4.856c8.647 8.502 13.86 10.967 23.297 11.015 11.54.058 24.178-6.388 24.178-12.333 0-1.34.954-2.723 1.879-2.723.391 0 2.617.684 4.945 1.52 6.07 2.177 9.63 2.965 14.61 3.231 4.94.264 8.548-.17 13.358-1.608 4.725-1.413 7.447-2.86 15.598-8.29 4.108-2.735 7.6-4.974 7.76-4.974s3.125 1.719 6.589 3.82c3.463 2.1 7.625 4.381 9.248 5.067 11.07 4.68 23.025 4.374 33.972-.867 1.958-.937 6.568-3.73 10.244-6.207s6.736-4.446 6.8-4.376c.062.07 1.455 2.92 3.095 6.336 1.64 3.415 3.699 7.266 4.577 8.559 3.8 5.596 8.175 9.751 14.083 13.375 6.081 3.73 9.832 8.686 10.219 13.505.384 4.78-1.703 9.019-7.722 15.687-4.698 5.204-5.873 7.235-5.861 10.125.012 2.892 1.7 6.228 4.67 9.224 4.805 4.848 12.346 6.287 23.435 4.473 2.474-.405 5.595-.738 6.935-.74 4.285-.006 6.903 2.096 11.892 9.549 3.444 5.144 10.974 17.755 10.974 18.378 0 .324-.351.552-.85.552-1.052 0-5.624-1.243-8.933-2.43-4.348-1.558-57.272-22.005-74.748-28.878-46.663-18.351-62.028-24.212-69.536-26.524-8.115-2.5-13.64-3.086-18.127-1.923-5.58 1.445-81.72 30.868-126.132 48.741-21.932 8.826-24.678 9.876-28.782 11.002-3.263.895-3.144.883-3.144.324",
        ),
      ]),
    ],
  )
}

pub fn guile() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 47.6 47.6"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M20.8 1a23 23 0 0 0 0 45.6V40a16.4 16.4 0 0 1 0-32.2z",
        ),
        attribute.attribute("fill", "#d0343f"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M26.9 1v6.7a16.4 16.4 0 0 1 0 32.2v6.7a23 23 0 0 0 0-45.6",
        ),
        attribute.attribute("fill", "#1a1a1a"),
      ]),
      svg.g(
        [
          attribute.attribute("word-spacing", "0"),
          attribute.attribute("text-anchor", "middle"),
          attribute.attribute(
            "style",
            "line-height:0%;-inkscape-font-specification:\"URW Gothic L Semi-Bold\";text-align:center",
          ),
        ],
        [
          svg.path([
            attribute.attribute("transform", "translate(-2.6 -461)scale(.2646)"),
            attribute.attribute("style", "line-height:1.25"),
            attribute.attribute("letter-spacing", "0"),
            attribute.attribute("font-weight", "600"),
            attribute.attribute("font-size", "112.6"),
            attribute.attribute("font-family", "URW Gothic L"),
            attribute.attribute("aria-label", "G"),
            attribute.attribute(
              "d",
              "M90 1846v-14.5h54.4v2q0 16.3-11.5 28.7l-.5.4q-12.5 12.8-31.5 12.8-18.7 0-31.7-11.9-12.6-11.6-13.5-29v-2.3q0-17.1 11.7-29.5 11.9-12.2 29-13.3l3-.1q16 0 28.5 9.7 8.8 6.8 12.2 16.2H122q-8-11-23-11-12.5 0-20 8.2-6.5 6.7-7.6 17l-.2 3q0 12.9 9.4 21 8 7.2 19.4 7.2 13.7 0 21.5-10 1.7-2 3-4.7z",
            ),
            attribute.attribute("fill", "#1a1a1a"),
          ]),
        ],
      ),
    ],
  )
}

pub fn hare() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 18432 18432"),
      attribute.attribute("version", "1.0"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M10224 936h-288l-288 144-288 144-288 432-360 360-144 360-216 360v1152l72 504 72 432 288 864 216 792 144 288 144 288v72l72 144-216 72-144 72h360v-144l72-72-216-504-216-576-216-864-288-864-72-720v-792l216-504 288-432 360-432 432-432 216-72h288l72 72 72 72v-72l72-72 144 72 216 72 216 216 288 216 144 288 144 360 144 1224 216 1296v648l72 648h72v-360l72-288 144 144 144 144h-144l-144-72v360h72v72l144-72h144v-216l-72-288 72 144 72 144v-144l72-144-72 288v216l72-72 72-144 72 144v72l144-216 72-144-72-72-72-144v144l72 72-72 72-72 72v-216l-72-216-144-360-72-360 72 288v288h-144v-432l-72-144-72-144 72 360v360l-72-72-72-72v-216l-72-288v576h-72l-72 72v-648l-72-216v-288h144v432l144-144 144-144v-216l-72-216v432h-144l-72-216v-648l72-432-72-216-72-216 72-648v-648l72 360 72 288v-648h-144l72-72v-72h576l288 144 288 144 144 144 144 216 144 360 216 432 144 720 72 792v1944l-144 72-72 72v144l144-72h72v216l72-144 72-144h-144l72-936V4104l-72-720-72-720-144-432-144-432-216-288-216-288-360-144-288-144h-648l-72 432-72 360v2016l-72-72-72-720-144-792-144-288-144-288-216-216-144-216-288-144-216-72zm2232 4896v72h-72v-72z",
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M12384 1080h-72v144h72v-144M12528 1152h-72v72h72zM12672 1152h-72v72h72zM9936 1224h-72v72h72zM10800 1224h-72v216l72-72v-144M12888 1224h-72v216l72-72v-144M11016 1440h-72v144h72v-144M10512 1584h-72v72h72zM11232 1872h-72v72h72zM9144 2016h-72v72h72zM11304 2016h-72v72h72zM12240 2160l-72-216v792l72-144v-432M10728 2664l-72-576v864l144 504 144 504v72h-72l-72-72-72-72 72-72v-144l-72 72-72 72 72 360v288h216v288l-72-72v-144l-72 72-72 72-72-72-72-144v360h144v288l-72-72-144-144v-216l-72-216-72-72v-72h72l144 72v-360h-216v-72l-72-144 72 216v216h-72l-72-72 72 360 144 288 72 288 144 288v72h-72l-72-144-144-216-72-144v-216l-72-72h-72l216 504 144 504v72l-144-216-144-288-72-288-72-216-72 72-72 72h-144l-216-72v144l144 360 144 288v72h-144l-72-360-144-360v-360l72-144-72 144-72 72h-144v-504l-72 216v144l-144-72-72-72 72 216 72 216h144l216 720 216 720 72-72h72l72 216 72 216h72l-72-72v-72h72l144 72-72-144v-216l72 144 72 72 72-72v-72l72 72 72 72v-432l144 144 72 72v-72l-72-72h144v144l72-72h72v-216l-72-144 144-72h216v-288l72 144 72 72v-216l72 144 72 72-72-864v-936l-72-432-72-432-144 72h-72v-216h144v-504h-72l-144-72v144l-72-72-72-144v1080h-72v-72zm288-216v72h-72v-72zm0 144v720l-72-144-72-216 72-216v-144zm-72 792v72h-72v-72zm144 360v288l-72 72v-504zm-216 576v72h-72v-72zm216 216v72h-72v-72zm0 144v144l-72 72v-216zm-936 720v72h-72v-72zm-216 432v72h-72v-72zm144 72h72v144h-216l72-144v-72z",
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M10368 2232h-72v720h72v-720M10512 2304l-72-144zv144h72v-72zM8856 2304h-72v72h72zM9648 2304h-72v72l72 144 72 144v-288zM9864 2304v288l72 144 72 144-72-288v-288zM10152 2520l-72-144v432l72-72v-216M10584 2520h-72v144h72v-144M12816 2520h-72v72h72zM9504 2592h-72v72h72zM12384 2664h-72v144h72v-144M9360 2736v288l72 144 72 144-72-288v-288zM9792 2736h-72v216l72-72v-144M12816 2736h-72v216l72-72v-144M13176 2880l-72-144v360l72-72v-144M9216 2880h-72v72h72zM10224 3024l-144-144v144l216 144 144 144v-216h-72l-72 72zM10584 2952l-72-144v360l72-72v-144M9072 2952h-72v144h72v-144M12816 3024h-72v216l72-72v-144M9792 3096h-72v72h-72v360l72-72v-72h72l72 72-72-216zM9936 3096h-72l72 144v144l72 72h72l-72-144v-144zM9216 3168h-72v144h72v-144M9072 3240h-72v144h72v-144M10656 3240h-72v144h72v-144M12240 3312l-72-144v360l72-72v-144M8568 3312h-72v216l72-72v-144M12528 3312h-72v216l72-72v-144M9288 3384h-72v144h72v-144M9576 3384h-72v72h72zM10440 3384v144l144 144 72 72-72-144-72-216zM9144 3672l-144-288v144l72 360 144 288v-288zM10296 3528l-72-144v144l72 144v144h72l144 72-72-144v-144zM13176 3456h-72v216l72-72v-144M10080 3600l-72-144v144l72 144 72 144v-216zM9360 3600h-72v216l72-72v-144M9864 3744h-72v72h72zM9936 3888h-72v144l-72 72 72 144 72 144h72v-216l-72-216zm0 216v72h-72v-72zM9576 3960h-72l72 216 72 144h72v-72l-72-144v-144zM12672 3960h-72v216l72-72v-144M10224 4032h-72v72h72zM13608 4176l-72-144v504l72-72v-288M13032 4248l-72-144v432l72-72v-216M8640 4248h-72v72h72zM9432 4248h-72v72h72zM12456 4320h-72v144h72v-144M9504 4392h-72v72h72zM9792 4392h-72v72h72zM10152 4464h-72v72h72zM9720 4608v144h72l72 72-72-72v-144zM10008 4608h-72v72h72zM9144 4968v216h72l72 72-72-144v-144zM12816 4968h-72v72h72zM12960 5040h-72v72h72zM12960 5184h-72v72h72zM13464 5328l-72-144v360l72-72v-144M13176 5400l-72-144v432l72-72v-216M13752 5400l-72-144v504l72-72v-288M7848 5760l-216-72v144l72 72-216-72h-216v72l72 72 360 216 432 144-216-144-144-144 144-72 144-72h648l-72-144v-72h-288l-144 72-72 72zM9360 5688h-72v216l72-72v-144M11088 5760h-72v216l72-72v-144M11304 5760h-72v216l72-72v-144M13104 5760h-72v216l72-72v-144M13320 5832l-72-72v144l-72 144 72-72 72-72zM13536 5760h-72v216l72-72v-144M13680 5904h-72v216l72-72v-144M7128 5976h-72l72 72v72h72v-144zM13896 5976h-72v144l-72 72 72-72 72-72zM6840 6048h-72v72l72 72 144 72 216 72-144-144-144-144zM11880 6120v-72l-216 72-216 72h72l72 72 72-72h72v72l-72 72h216v-72l72-144zM6480 6120h-72l72 72 144 72h72v-72l-72-72z",
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M8496 6120h-144l72 72h144l144-72zM14472 6120h-72v72h-72v216l72-72 72-144zM11304 6264l-144-72 72 72 144 144h144v-72zM7560 6264h-72v72h72zM6264 6336h-72l72 72v72h144v-72l-72-72zM7344 6336h-144l72 72 216 72 216 144 72-144 72-72h-144l-72-72 72 72v72h-144l-72-72zM8280 6336h-72v144h360l-144-72-72-72zM11160 6408l-144-72 72 72 144 144h144v-72zM14688 6336h-72l-72 72-72 144h144l-72 72v144h144v-144l72-72h-144v-144zM6912 6408h-72l144 72 216 144h144l216 72-288-144-288-144zM8856 6552l-72-144v216l72 72h72l72-72zM10872 6480l-144-72 72 144 144 72h72v-72zM6048 6552l-288-72 72 144 144 72h-216l-216-72 72 72 144 144-144 72-72 144h-288l-216-72v144h288v72l-72 72h-288v144l144 72 216 72 144-72 216-72 72 72v72h288l-216-144-216-144h216l144 144 216 72-144-144-144-144h-504l72-72h360v-144h216l72 72 72 144h144l-72-144-144-144v-144l72-72 72-72 288 144 288 144h144l-360-144-288-216zM6768 6552l-144-72 72 72 144 144h144v-72zM9864 6552l-72-144v360h72l72 72v-144zM11160 6624h-72v72h144v-72zM7128 6696h-72v72h72zM8712 6696h-72l72 144 72 72h72v-144l-72-72zM14832 6696h-72l-72 72-72 144v72h72l72-144 72-72zM13968 6768h-72l-72 144-72 144h72l72-144z",
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M5328 6840h-72v72h144l72 72-72-72v-72zM6336 6840h-72l72 144 72 144h144l-72-144-72-144zM14112 6840h-72l-72 144-72 144h144l-72 144v144h72l72-72v-144l72-144-72 72h-72v-144zM7056 6912h-72v72h72zM14760 7128h-72v504l72 504 72 144 72 144 288 288 216 288v432h144v-360l-72-360-72-72-72-72-72-504-144-576-144-144-72-216zm72 144h72l72 216 72 144-72 72-72 72h-72l-72-72v-432zM8064 7200h-72l72 72h144v-72zM6624 7344h-72v72h144v-72zM14184 7344l-72 144-72 144h144v-144l72-144zM4752 7488h-72v144h144v-144zM6480 7560h-72v72h144v-72zM14328 7560h-72l-72 144-72 216h144l72-144v-216M5112 7632h-72l72 72v72h144v-72l-72-72zM9072 7632h-144l72 144v144l144-72h144l-72-144v-72zM10296 7704l-144-72v72l216 144 288 144-144-72-72-144zM10440 7632l72 72v72h72v-72l-72-72zM11592 7632h-144l-144 72h-72l-144 144-144 72v792l144 360 144 360 288 72 288 72h216l288-144 288-72 72-144 72-144-144-432-72-432-144-216-144-144-216-144-216-72zm720 504 144 144v216h-144v72l72 144h-144v72l72 72h-288l72-144v-144l-72-72h-72v-288l72-144 144-144zm0 864v72h-72v-72zM4896 7776h-72v144h360l-144-72-72-72zM8784 7776h-72v72h144v-72zM10224 7848l-144-72v72l216 72 144 144v-72l-72-72zM4608 7848h-144v144h144l72-72 144-72zM5328 7848h-144l72 72h144l216 72 216 72-144-144-144-72zM6264 7920h-216l72 72h216l144-72zM8712 7992h-72v72l-72 144h144v-144l72-72zM8928 7992h-72v144h72v72l144-72h72l-72-72v-72zM10080 7992l144 144 144 216h72l-144-216-144-144zM6048 8064h-144v72h144l216 72-72-72v-72zM4464 8136h-72l72 72h144v-72zM4968 8136h-216l288 72 288 72h360l-216-72-216-72zM6840 8136h-72v72h144v-72zM14472 8208h-72v144l-72 72v72l72-72 72-144zM7776 8280h-72l72 72h144v-72zM8856 8280h-288v144l144-72h144v144h-216l72 72h72l216-72 216-144v-72zM9432 8280h-72v72h72zM4392 8352h-144v216h-144l-72 72h360v-72h-72l72-144 72-72zM5112 8352h-72l-288 72-216 72h360l72 72 72 72h216l216-72h-504v-144l288 72h288l-144-72-144-72zM6048 8352h-216l72 72h288l144-72zM9576 8352h-72v72h72zM10584 8352h-72v72h72zM14616 8352h-72v144l-72 72 72-72 72-72zM6984 8424h-72v72h72zM7920 8424h-144l-216 72-144 72h288l144-72 216-72zM14760 8496h-72v72h72zM7992 8568h-72l72 72h144v-72zM9144 8568h-72l-72 144-144 144h144l144-144 72-144zM9648 8568h-72v72h72zM7704 8640h-216l72 72h216l144-72zM14688 8640h-72v144h72v-144M5184 8712h-216v144l-72 72h216l288-72-72-72v-72zM6048 8712l-288 72-216 72h504l72-72v-72zM14832 8712h-72v144h72v-144M4248 8784h-144v72l-72 72h144l72-72 144-72zM4536 8784h-72v144h144v-144zM7992 8784h-72l72 72h144v-72zM9288 8784h-72l-72 72v288l72 144 144-144 144-144h-144l-144 72 72-72 72-72v-144zM9648 8784h-72v72h72zM7704 8856h-144l72 72h144l144-72zM9792 8856h-72v72h144v-72zM15048 8856h-72l-72 72v72h72l72-72zM14760 8928h-72v72h72zM4464 9000h-144l72 72h144l144-72zM7920 9000h-72v72h144v-72zM8136 9000h-72v72h72zM14544 9000h-72v144h72v-144M5184 9072h-72v72h144v-72zM8928 9072h-72v72l-72 72 72-72h144v-72zM9792 9072h-72v72h144v-72zM14904 9072h-72v72h72zM4032 9144h-72l72 72h144v-72zM4968 9144h-72l-360 72-288 72h504v216l72 216h72l144-72h72l144-72-72-72-72-72h216v-216l-216 72h-216l72-72 144-72zM5760 9144h-72l-72 72v72h72l72-72zM8208 9216h-216l72 72h216l144-72zM14616 9216h-72v144h72v-144M6840 9288h-72v72h144v-72zM7920 9288h-72v72h72zM8928 9288h-72l-72 72v72h72l72-72zM9432 9288h-72l-72 144-144 144v216h144l72-144v-144l72-72v-72l72-72zM9720 9288h-72v72h144v-72zM5832 9360h-72v72h72zM10008 9360h-72v72h144v-72zM14760 9360h-72v72h72zM14976 9360h-72v72h72zM4032 9432h-144v72l-72 72h144l72-72 144-72zM6984 9432l-144 72-144 72h216l72-72zM8208 9432h-144v72l-72 72 216-72h144v-72z",
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M4392 9504h-144v72l-72 72h144l72-72 144-72zM7848 9504h-72v72h144v-72zM9000 9504h-72v144h72v-144M15120 9504h-72v144l-72 144v72h72l72-144v-216M15552 9504h-72v72l-72 72h144v-144M6624 9576h-72v72h72zM7344 9576h-72v72h144v-72zM8496 9576h-72l-216 72-216 72h360l144-72 144-72zM7056 9648h-72l-144 72-72 72h144l72-72 144-72zM10008 9648h-144l72 72h144l144-72zM4176 9720h-144l-216 72-144 144h72l288-72 288-144zM4392 9720h-72l72 72v72h144v-144z",
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M5112 9720h-216v72h-72l72 216 72 144h144v144h-72l-72-72-216 144-216 144h-144l144-72 144-72 72-144 72-72h-216v72l-72 72h-504l72-72h72l-72-144v-72h216v72l-72 72h72l72 72 72-72 144-144h-216l-216-72-144 72h-144l-144 144-144 144v72l144-72 72-72v216l-144 144-144 72h216v144l-144 72-144 72v144l144-72 144-72v144l72 72h-360v144l-72 72 72 72v72h-72l-72 72 72 72v72l144-72 72-144-72 216-72 144 72 72 72 72-72 144v144h144v72l-72 144h72l144-72 216-72-216 144-144 216 72 72 72 72-72 144v72h72l216-144 216-72-216 144-144 144 72 288 72 216 144 216 216 216-72 72-72 144h-504l-504 72h1152v-144h144l-72 72v144h288v216h-144l-144 72h-936l360 72 360 72h-216l-144 72h1152v-144h-216l-216 72v-144h360l144 72h144v216h-360l-360 72h-360l-360 72h720l720-72h72l144-72v216h-432l-360 72h1008v-144h144v216h-432v72h360l216 72 144-72 144-72 72 144v144l144-72h72v144H5472l-1008 72h2088l72-144 72-144h144v72l-72 144 216 72 216 72h360l-648 72-576 72h1584l-144-72-144-72h216l144-72 72 72 72 72 72-72 144-72 216 72 216 72v-144h288l360 72v144h-504l-504 72h1872v-72l-72-72h-648l72-72h72l144-144 144-72v216h144v-216h144v216l72-72 144-144h144v144l144-72 72-144 72 144v72h288l72-144 144-72 72-72 72 144 144 72v-72l72-72h144l144-72v216h144v-216l72-72h144v216h144v-144l72-144h72l144 72v-144l72-216 72 144v72l144-144 72-144 72 72h144l-72-144v-144h144v72l72 72v-216h216v144h144v-216l-72-144h144l72 72 72 72-72-216v-216l72 144 144 144v-144l-72-216h144l72 72 72 72v-144l-72-72h-72v-144h216v72l72 72h72v-72l-72-72-72-144v-72l72-144 144 72h144l-144-72-72-72 72-144v-72l144 72h144l-72-72-72-144v-72l72-72h-216v-144h144l144 72v-144h-216v-144h288v-72l72-72h-72l-72-72h144l-72-216v-144l72-72 144-72h-216v-144h288l-144-72-72-72-72 72h-72l-72-72v-72h72l72 72v-144l-144-72h-72l-72 72-72 144h-144v-216l72-144 288-360 360-288h144l-144-144-144-72-216 216-288 216-216-144-216-216h-216v144l144 216 216 144v432l72 360h-144l-72-72v216l-72-144-72-216-72 216-72 144v-144l-72-216-72 216v216h-144v-288h-72l-216 216-144 144v-216h-288v216h-144v-432l-72 144v72l-72 144v72l-144-216-72-216v288h-144v-360l-72 144v144h-144v-144l-72-216v432l-72-72h-72v-360h-144v288h-216v-144l72-72 72-144v-144l-144 216-72 144h-144v-144l72-144h-144v72l-72 144h-144l72-216v-216l-144 144-72 144-72-72v-72l-72-144-144-72-72 72-144 72v-360l-72 72-144 72v-72h-72l144-144 72-144h-144l-144 216-216 216h-144l72-72 144-144 144-216 144-216h-144l-72 72-72 72v-144l72-144h-144v72l-72 72h-72v-72l72-72 72-72v-144l-144 72h-72l72-72v-144h-72l-144 144-72 72v-144l144-144 144-144h-144l-72 72-72 144-72 144h-216l-72 144-72 72 72-72 144-72h72l72 72v288h144l216-72-216 144-216 144v144l144-72 216-144v-72l72-72v288h72l72-72-72 72v144h-144v-144l-144 72-144 72v144l72-72 72-72h144l-72 72-72 72v144l144-72 72-72v144h-72l-72 72 72 144v72l72-72 72-72v-144l72-72 144-72 144-72v72l-144 288-216 216v144l72-72 144-144 72-144 72-144v72l72 72-144 216-72 216 72 72h72l-72 360v288l72-144 72-144h72l-72 432-72 432h-144v144l72 144h-144l-72-72-72-72-72 216-144 288h-144l72 144v216h-144v-360l-72-288 72-216 72-216-144 144-72 144v432l72 360h-144l-72 72v216l-72 72h-72v-216l72-216h-144v144l-72 216h-144v-288l72-288h216v-72l-72-144 144-72 72-144v-216l72-216-72 216-144 144-216 288-216 216h-144l-72 216-72 216-72 72h-72l144-216 72-288v-216h288l72-72-72-144v-72h-288l-216 72-144 72h-144v-72l72-144-72 72h-144l-72-72-72-144 144-144 72-216v-288l-144 288-144 216 72 72v72h-72l-144-72v72h-72v288l-72 216 72-72 144-144v216l-72 72-144 72-72-72-144-144 72-216 72-216v-288l-144 432-144 360v144l144-72h144l-216 144-144 144-72 216-72 216-72-72v-72l72-216 144-216v-288l-216 360-144 288h-72v-72l144-288 144-288v-144l-216 216-144 216 72-144 72-216v-144l-72 72-144 72v-72h-72l72-144v-72h-144l-72 144-144 216h-360v-144h216l144-144 144-144v-144h360l-72 144v144l72-72h144v216h288l72-288 72-216-72-72-72 144v144h-144l72-144 72-216h-72v-72l216-288 216-360h-72l-72-72-144 72-144 72-144 72h-72v-216l-72-216h144v-72h-72l-144 72-72 72h-72v-72l216-144 144-144h-144l-144 72-144 144v-72h-72l-144 288-216 288h-72l72-144v-144h-144l72-144v-144l144-144 216-144h-144l-72 72v-144l72-72 144-72-216 72-144 144v216l-144-72-72-144v-144l216-144 216-144h-144l-72 72-72 144h-144l144-216 216-144-144 72-144 72-72-72h-72l72-72 72-72 72-72 72-144-216 72h-288l-216 72-216 144 72-72v-144l144-72h144l72-72h72l216-72 288-144h-360l144-72 144-72h-432l72-72h144v-216zm72 72v72h-72v-72zm-1008 576h216l-144 72h-216l-72-72zm0 144h72v72l-72 72h-288l72-72 144-72zm1080 72h72v72h-144v-72zm-216 72h72v216h-144l-72 72h-216v-144l144-72zm-432 216 72 144v72h-72l-72-72h-144l72-144v-144zm-432-72h72v72h-144v-72zm-144 72v72h-72v-72zm1008 144h72v72l-144 72-216 144v-216h144zm-504 216v72h-72v-72zm144 0v72l-72 72v144l-72-72h-72l72-72zm-1008 72v144h-144l72-72v-72zm504 0h216l-144 72-72 72h-288l72-72v-72zm792 72h72l-72 72-72 72h-72v-144l72-72zm5544 0h72v72l-144 288-144 216v-144l72-216 72-216zm-6696 72v72h-72v-72zm1296 72h72v144l-216 72-144 72-72 72h-72l144-144 216-216zm5616 0h144l-144 72h-72v216l-144 144-72 72 72-144 72-216 72-72v-72zm-6408 72v72h-72v-72zm6552 72v72l-144 216-72 288h-72v-72l144-216 72-288zm-6336 72h72v72h-144v-72zm5616 0v72h-72v-72zm-4968 72h72l-144 72-72 144h-144l72-144 72-72zm-1512 72v72h-72v-72zm216 0v72h-72v-72zm2232 0-72 144v72l72-72h72v72l-72 72-72 144v144h72l72-72-72 144v144l-72 72h-72l72-144v-216l-72 144-72 72v-144l-72-144v-144l72 144 72 72v-144l72-72-72-72h-72l72-144 72-72zm5688 72v72h-72v-72zm1800 0v72h-72v-72zm1296 0v72h-72v-72zm-9720 72h72v72l-72 72h-144v-144zm9432 72 72 144v216l-72-72-72-144v-288zm-10656 72-72 72-72 72h-144v-144h144l144-72zm1008-72v72h-72v-72zm6624 72v144l-72 72v-360zm360 0v144l-72 72v-360zm1656-72v144l-72 72v-216zm720 0v144h-72v-144zm576 72h72v144h-72v-72l-72-72zm-10296 72v144h-72v-144zm648 0h72v72h72l-144 144-72 72h-216l72-72v-72l72 72h72v-216zm288 0h72v72h-144v-72zm720 0v72h-72v-72zm6624 0h72v504h-72v-288l-72-216zm-1152 72v72h-72v-72zm2664 0v72h-72v-72zm-8856 144-72 144-144 72-72-72 72-144 144-72zm-864 0v72h-72v-72zm1944 0v72h-72v-72zm4104 72v144l-72 72h-72v360l72-144v-144h72l72-72v-288h144l-72 72v72l144 144 144 144-72 216v288h72l72-72v216h-216l-288 72v-360l-72 216-72 144h-72v-216l72-216-144 72h-72v-216l72-216 144-72 72-72v-288zm2736-72v144h-72v-144zm1440 0v72h-72v-72zm-10512 72v72h-72v-72zm1296 0h72v144l72 144-216 144-144 144-72-72 72-72 144-144v-72l-144 72h-72l72-144 144-144zm6264 0v144h-72v-144zm-7200 72h72v72h-144v-72zm1656 144 144 144-72 72v72l-72-72v-144l-144 72h-72l72-144 72-144zm4824-144v144h-72v-144zm144 0h72v144h-72v-72l-72-72zm-7416 72v144h-144l72-72v-72zm8712 0h72v144h-216l72-72v-72zm-8064 72v72h-72v-72zm288 0v144l-432 360-360 288 72-144 72-144 288-216 288-288zm5400 0h72v144l-72 144-72 72v-360zm4464 0h72v72h-144v-72zm-576 72h72v144h-72l-72 72v-216zm216 0 144 72v216l-72-72v-144h-72l-72-72zm-2952 144v144h-72v-144zm144 0 72 72v144l-72-72h-72v-144zm2016 72 144 144v144l-144-144-144-72v-144zm-2376 72v72h-72v-72zm1800 0 72 72v144l-72-72h-72v-144zm-2808 144 72 72-72 216v288h-72l-72-72h-144l-144-72v-144l144 72 72 72 72-72 72-144v-288zm3240-72v72h-72v-72zm-1080 72v72h-72v-72zm144 0v72h-72v-72zm1800 0h72l72 72 72 144h-216v-216m-2736 144 144 144-72 216v144l-72-144-72-144v-288zm1728-72v72h-72v-72zm-5184 72h72v216l-144 72-144 72v-216l72-72 72-72zm2304 0v144h-72v-144zm-2952 216v216l-72 72h-72l-72-72 72-144 72-144zm3888 0v72h-72v-72zm720 0v72h-72v-72zm2088 0 72 72v216l-72-72-72-144v-72zm-9864 72v72h-72v-72zm3312 0h72v144l-72 144-72 144v-72l-72-72 72-144v-144zm2952 0h144v144l144-72h72v144h-72l-72 72-144-144-144-144zm-3456 144 72 72-72 144-144 72v-288h72v-72zm-1152 0v144h-144l72-72v-72zm5184 0v144h-72v-144zm288 0v144l-72 72v-216zm504 0h72v72h-144v-72zm-5832 144h72v72l-144 288-144 216h-72v-72l144-216zm1224 72 72 72v144l-72-72h-72v-288zm648-72h72v144h-144v-144zm648 0v72h-72v-72zm1152 72 72 72 72 72h144v-72l72-144v216l72-72h72l72 72 72 72v144h-72l-144-72v144l-72-144-72-144v216l-72-72h-144v144l-72 144v-360h-144l72-144v-144zm2160-72v144h-72v-144zm-288 72h72l72 72v72h-72v-72zm-4752 72v72l-72 144-72 144h-72v-72l72-144 72-144zm1584 0h72v216l-72 72h-144v-144l72-144zm3672 0v144h-72v-144zm360 0v144h-72v-144zm-4536 72v72h-72v-72zm5544 0v72h-72v-72zm-7200 72v72l-72 144-72 144h-144l144-216 72-144zm4320 0 144 72v432h-144v-360l-72 144-72 72v-360zm-3456 72v144h-144l72-72v-72zm3888 72v72l144-72h144v144l-72 144-72 72v-216h-72l-72 72-72-72-72-72 72-72v-72zm576 72v144l72 72h144l-72 216v144l-72 72h-72l-72-288v-288l-72 72-72 72v-216l72-72 144-72zm-2448-72v144h-72v-144zm-2304 72h72v72h-144v-72zm1800 0v72h-72v-72zm-1080 72v72h-72v-72zm4680 72h72v216h-216v-72l-72-72h72v-72zm360 0v72h-72v-72zm288 0h72v144l72 72-72-72h-72v-144m-5256 72h72v144h144l144 72h-288l-216-72v-72h72v-72zm4320 0v144h-72v-144zm-3456 72h72v72h-144v-72zm1512 0v144h-72v-144zm648 72h72l-72 72v144h-72v-216zm288 72h72v360h-144v-216l-72-144zm432 0h72v144h-72l-72 72v-216zm-1368 144v72h-72v-72zm648 144v72h-72v-72zm-4680 72v144h-144l72-72v-72zm3600 0h72v144h-144v-144zm864 0v72h-72v-72zm-3384 432v72h-72v-72z",
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M10872 12816h-72l-72 144v216l72 144 144 72v-216l72-144v-144l-72 144-144 144 72-144zM5688 9720h-72v72h144v-72zM6624 9792h-72v72h144v-72zM8640 9792h-72l-216 72-144 72h288l72-72 144-72zM15624 9792l-144 72-72 72 72 72 72-72zM7056 9864l-144 72-72 72h144l72-72zM9072 9864h-72v72l-72 72h144l72-72v-72zM5688 9936h-72v144l144-72h216l-144 72-144 144 72 144 72 216 216-144 288-72v-144l-144 72-144 72h-72l144-144 144-144-216-72-216-72zM10152 9936h-72v72h72zM6696 10008h-72v72h144v-72zM8712 10008h-72l-288 144-288 72 216-72h288l72-72 144-72zM11736 10008h-72l-144 144-72 144 144-72 216-144v-72zM12096 10008h-72l-144 144-72 144 144-72 216-144v-72zM12672 10008h-72l-144 216-144 144 144-72 144-72v-144zM15624 10008h-72l-72 72v144h72l72-72 72-144zM7128 10080l-216 144-216 72v72l216-144 216-72zM12312 10080h-72l-72 144-72 72 144-72 144-72v-72zM10368 10296h-72l72 72 144 72h144l-144-72-72-72zM15552 10296h-144l72 72 72 72 72-72 72-72zM8064 10368l-144 72-72 72h144l72-72zM8424 10368h-72v72h144v-72zM6408 10512v-72l-288 216-288 144h216l-144 72-72 144h216l216-144 216-144v-72l-144 72-144 72h-72l144-144zM7632 10440h-72v72h72zM8712 10440h-72v72l-72 144h144v-144l72-72zM7056 10656h-72l-72 144-72 72 72-72 144-72zM7488 10656h-72l-144 72-72 144 72 72 72-144zM8208 10656h-72l-72 72v216l72 72 72-144 72-216zM9000 10656h-72l-72 144-72 144h72l72 72v-144l72-144zM8424 10728h-72v144l-72 72v72l72-72 72-144zM15552 10800l-144-72 72 144v72h144v-72l72-72zM6480 10872l-288 144-216 72v72l72 144 72 72 144-72 216-144v-288M8568 10872h-72v72h-72v216l72-72 72-144zM7416 10944h-72v72l-72 72h144l72-72v-72zM6912 11016h-72l-72 72v72h72l72-72zM8712 11016h-72l-72 72v144l72 72 72 144 72-144 72-216-72 144-144 72v-144zM15336 11088l-72-72 72 144 72 144h144l-72-72v-144zM12744 11088h-72l-144 144-72 144 144-72 144-72v-144M13032 11088h-72l-144 144-72 144 144-72 144-72v-144M12384 11160h-72v72l-72 72 72-72h144v-72zM13248 11160h-72l-144 144-72 144 144-72 216-144v-72zM8064 11232h-72v72h72zM9072 11232h-72l-72 144-72 144v72h72l72-144 72-144zM13608 11232h-72v72l-72 72 72-72h144v-72zM15264 11304l-72-144v360h72l72 72v-216zM7056 11304h-72l-72 72-72 144v72h72l72-144 72-72zM9360 11304h-72v144h72v-144M13392 11376h-72v72h72zM7200 11520l-72-72v72l-72 72v72h144v-144M7488 11520h-72l-72 144-144 144v72h72l144-144 72-144zM7848 11592l-72-72-144 288-216 216h72l72-72 144-144zM8352 11520h-72v72h72zM8208 11592h-72v72h72zM8496 11592h-72v72h72zM9072 11592h-72v144l-72 72 72-72 144-72v-72zM9360 11664h-72l-144 144-72 144 144-72 144-144zM9576 11664h-72l-144 216-144 144v144h216l-72-72v-72l72-216zM8424 11736h-72l-72 72v72h72l72-72zM8640 11736h-72l-72 144-72 72 72 72 72-144zM6624 11808h-72v72h144v-72z",
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M9648 11808h-72l-72 144-72 72 72 72h72l-72 72v144h144l144 72v144l144-144 72-216v-72l-144-144-144-144zm0 144v72h-72v-72zM7920 11880h-72l-72 144-144 144v72h72l144-144 72-144zM8136 11880h-72l-144 288-144 216v72l144-72 72-72 72-216 72-144zM8784 11952h-72l-72 72v72h72l72-72zM8856 12096h-72l-72 72v72h72l72-72zM7128 12168h-72l-144 216-144 216v72h144l144-288 144-216zM8496 12168h-72v216l72-72v-144M9072 12312l-72-72-72 144-144 144v144l72 72h72v-72l-72-72 144-144zM7344 12312h-72l-144 216-216 216 72 72 144-144 72-144 72-72zM8208 12312h-72l-72 72-72 144v72h72l72-144 72-72zM8640 12384h-72v144h144v-144zM7488 12456h-72l-72 144-144 144v72h144l72-216 144-144zM8352 12528v72h-72v576h144v-648zM9216 12528h-72l-72 72v72h72l72-72zM9504 12528h-72v144l-72 72v144l72-144 144-144v-72zM3312 12600h-288l144 72h288l144-72zM9792 12600h-72l-72 144-72 144v72h72l72-144zM2520 12672h-72v72h72zM7920 12672h-72v216l72-72v-144M9216 12744h-72v72l-72 72h144v-144M10008 12744h-72v72l-72 144h144v-216M8136 12816h-72v72l-72 72h144v-144M8712 12816h-72l-72 72-72 144v72l72 72 72-144zM3384 12888h-360l144 72h432l216-72zM2304 12960h-72v72h72zM2592 12960h-144l72 72h144l144-72zM8856 12960h-72v144l-72 72v72h72l72-144 72-144zM7848 13032h-72v72h72zM3600 13104l-432 72-432 72h864l72-72v-72zM7992 13104h-72v72h72zM9864 13104h-72v72h144v-72zM9576 13176l-72 144v72l-72 72v72h144v-144l72-144zM2304 13248h-72v72h72zM3384 13320h-360l144 72h432l216-72zM3672 13464h-144l-288 72-216 72h432l144-72 216-72zM2736 13608h-144l72 72h144l144-72zM9144 13680l-72-144v360l72-72v-144M3600 13680h-288l144 72h288l216-72zM3960 13968h-144l-432 72-432 72h792l144-72 216-72zM3960 14112h-72l-144 72-72 72h216l216-72v-72zM3240 14184h-216l72 72h288l144-72zM3600 14184h-72v72h72zM3168 14328h-72v72h72zM4104 14544h-360l-288 72-288 72h648l360-72 360-72zM3240 14760h-288l144 72h288l144-72zM3744 14904h-72v72h144v-72zM3528 15120h-144l72 72h144l144-72zM13824 15192h-216l72 72h288l144-72zM4608 15264l-216 72-216 72h432v-144M13392 15264h-144l72 72h144l144-72zM5184 15408h-72v72h72zM5328 15408h-72v72h72zM4392 15480h-504l216 72h576l288-72zM13032 15552h-72v72h72zM13320 15552h-216v72h216l144 72v-144zM13032 15768l-432 72-360 72h864v-72zM12024 15840h-72v72h72zM11304 15984h-504l504 72 504 72h-216l-144 72h-360l-360 72h864l72-72h144v-216zM8424 16272h-720l360 72h720l432-72zM9288 16272h-72v72h72zM10224 16272h-72v72h72zM10368 16272h-72v72h72zM6912 16344h-432l216 72h432l288-72zM12960 16344l-504 72-432 72h864l72-72zM5760 16416h-360l144 72h360l216-72zM11880 16416h-72v72h72zM4968 16488h-216l72 72h216l144-72zM10512 16488h-792l360 72h792l432-72zM11664 16488h-72v72h72zM9000 16560h-360l144 72h360l216-72zM7992 16632h-288l144 72h288l144-72zM7272 16704h-144l72 72h144l144-72zM6552 16776h-144l72 72h144l144-72zM6840 16776h-72v72h72zM5904 16848h-72v72h72zM12096 16848h-288l144 72h288l144-72zM11376 16920h-432l216 72h432l216-72zM10080 16992h-504l216 72h576l288-72zM8784 17064h-504l216 72h504l288-72zM7848 17136h-288l144 72h288l144-72zM7128 17208h-144l72 72h144l144-72zM10728 17424h-216l72 72h288l144-72zM10008 17496h-360l144 72h360l216-72z",
        ),
      ]),
    ],
  )
}

pub fn haskell() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 181"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "m0 180.664 60.222-90.332L0 0h45.166l60.222 90.332-60.222 90.332z",
        ),
        attribute.attribute("fill", "#F97E2F"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m60.222 180.664 60.222-90.332L60.222 0h45.166L225.83 180.664h-45.166l-37.637-56.457-37.639 56.457z",
        ),
        attribute.attribute("fill", "#95653A"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m205.757 127.971-20.072-30.11 70.257-.002v30.112zM175.647 82.805l-20.074-30.11 100.369-.002v30.112z",
        ),
        attribute.attribute("fill", "#F97E2F"),
      ]),
    ],
  )
}

pub fn idris() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "-100 -100 595 841"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute("transform", "translate(22)"),
        attribute.attribute("style", "fill:#8a0819;fill-opacity:1;stroke:none"),
        attribute.attribute(
          "d",
          "M79.077 85.235c73.08 22.117 91.775 40.337 117.469 106.37-4.984-80.517-37.208-114.082-117.469-106.37 18.827-67.89 0 0 0 0M-22.208 211.874C25.235 226.484 80.324 238.16 100.68 328.8c8.404-113.077-45.134-118.838-122.888-116.925 90.649-302.18 0 0 0 0",
        ),
      ]),
      svg.path([
        attribute.attribute("transform", "translate(22)"),
        attribute.attribute("style", "fill:#8a0819;fill-opacity:1;stroke:none"),
        attribute.attribute(
          "d",
          "M9.848 139.77c71.289 14.732 116.732 34.088 143.292 126.084 6.093-118.68-59.046-130.596-143.292-126.084 78.39-131.188 0 0 0 0",
        ),
      ]),
      svg.path([
        attribute.attribute("transform", "translate(22)"),
        attribute.attribute("style", "fill:#8a0819;fill-opacity:1;stroke:none"),
        attribute.attribute(
          "d",
          "M103.33.379c389.022 253.662-86.412 258.144 17 552.638l61.216 17.827C12.903 342.22 556.898 224.698 103.33.379",
        ),
      ]),
    ],
  )
}

pub fn java() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "-40 -40 320 432.5"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M82.554 267.473s-13.198 7.675 9.393 10.272c27.369 3.122 41.356 2.675 71.517-3.034 0 0 7.93 4.972 19.003 9.279-67.611 28.977-153.019-1.679-99.913-16.517M74.292 229.659s-14.803 10.958 7.805 13.296c29.236 3.016 52.324 3.263 92.276-4.43 0 0 5.526 5.602 14.215 8.666-81.747 23.904-172.798 1.885-114.296-17.532",
        ),
        attribute.attribute("fill", "#5382A1"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M143.942 165.515c16.66 19.18-4.377 36.44-4.377 36.44s42.301-21.837 22.874-49.183c-18.144-25.5-32.059-38.172 43.268-81.858 0 0-118.238 29.53-61.765 94.6",
        ),
        attribute.attribute("fill", "#E76F00"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M233.364 295.442s9.767 8.047-10.757 14.273c-39.026 11.823-162.432 15.393-196.714.471-12.323-5.36 10.787-12.8 18.056-14.362 7.581-1.644 11.914-1.337 11.914-1.337-13.705-9.655-88.583 18.957-38.034 27.15 137.853 22.356 251.292-10.066 215.535-26.195M88.9 190.48s-62.771 14.91-22.228 20.323c17.118 2.292 51.243 1.774 83.03-.89 25.978-2.19 52.063-6.85 52.063-6.85s-9.16 3.923-15.787 8.448c-63.744 16.765-186.886 8.966-151.435-8.183 29.981-14.492 54.358-12.848 54.358-12.848M201.506 253.422c64.8-33.672 34.839-66.03 13.927-61.67-5.126 1.066-7.411 1.99-7.411 1.99s1.903-2.98 5.537-4.27c41.37-14.545 73.187 42.897-13.355 65.647 0 .001 1.003-.895 1.302-1.697",
        ),
        attribute.attribute("fill", "#5382A1"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M162.439.371s35.887 35.9-34.037 91.101c-56.071 44.282-12.786 69.53-.023 98.377-32.73-29.53-56.75-55.526-40.635-79.72C111.395 74.612 176.918 57.393 162.439.37",
        ),
        attribute.attribute("fill", "#E76F00"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M95.268 344.665c62.199 3.982 157.712-2.209 159.974-31.64 0 0-4.348 11.158-51.404 20.018-53.088 9.99-118.564 8.824-157.399 2.421.001 0 7.95 6.58 48.83 9.201",
        ),
        attribute.attribute("fill", "#5382A1"),
      ]),
    ],
  )
}

pub fn javascript() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 256"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute("d", "M0 0h256v256H0z"),
        attribute.attribute("fill", "#F7DF1E"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m67.312 213.932 19.59-11.856c3.78 6.701 7.218 12.371 15.465 12.371 7.905 0 12.89-3.092 12.89-15.12v-81.798h24.057v82.138c0 24.917-14.606 36.259-35.916 36.259-19.245 0-30.416-9.967-36.087-21.996M152.381 211.354l19.588-11.341c5.157 8.421 11.859 14.607 23.715 14.607 9.969 0 16.325-4.984 16.325-11.858 0-8.248-6.53-11.17-17.528-15.98l-6.013-2.58c-17.357-7.387-28.87-16.667-28.87-36.257 0-18.044 13.747-31.792 35.228-31.792 15.294 0 26.292 5.328 34.196 19.247L210.29 147.43c-4.125-7.389-8.591-10.31-15.465-10.31-7.046 0-11.514 4.468-11.514 10.31 0 7.217 4.468 10.14 14.778 14.608l6.014 2.577c20.45 8.765 31.963 17.7 31.963 37.804 0 21.654-17.012 33.51-39.867 33.51-22.339 0-36.774-10.654-43.819-24.574",
        ),
      ]),
    ],
  )
}

pub fn julia() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 383.37 258.84"),
      attribute.attribute("space", "preserve"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.g([attribute.attribute("fill", "#252525")], [
        svg.path([
          attribute.attribute(
            "d",
            "M77.642 209.377V99.92l-32.427 8.921v116.397q0 9.204-1.416 12.39t-4.107 3.186q-1.274 0-2.832-.992-1.557-.99-3.823-3.964-1.982-2.69-5.027-5.452-3.044-2.76-8.142-2.761-6.797 0-10.832 3.398T5 239.397q0 5.947 7.222 10.195 7.221 4.248 20.815 4.248 10.055 0 18.267-1.628 8.212-1.63 14.09-6.443 5.876-4.814 9.062-13.523t3.186-22.869zM122.68 103.034H90.393v74.907q0 6.939 2.903 13.027 2.903 6.09 8 10.62 5.099 4.532 11.895 7.151 6.797 2.62 14.727 2.62 6.796 0 14.018-3.257 7.221-3.256 13.594-8.638v9.913h32.285V103.034h-32.285v76.748q-3.682 5.664-8.638 9.416t-8.638 3.753q-3.255 0-6.088-1.204-2.832-1.203-4.956-3.186t-3.328-4.744-1.204-5.876zM232.676 209.377V51.35l-32.143 8.92v149.107zM245.534 108.84v100.537h32.285V99.92zM345.943 154.436v30.727q-4.957 3.682-8.992 6.09-4.036 2.406-8 2.406-1.983 0-3.682-1.203-1.7-1.205-3.116-3.186-1.416-1.983-2.194-4.744a21 21 0 0 1-.78-5.735q0-3.823 2.408-7.363t6.301-6.655q3.894-3.116 8.638-5.735a102 102 0 0 1 9.416-4.602m32.426 54.941v-79.722q0-6.654-2.549-12.036-2.548-5.38-7.93-9.204-5.38-3.822-13.664-5.876-8.284-2.053-19.753-2.053-9.345 0-17.7 1.982-8.355 1.983-14.727 5.38-6.372 3.4-10.124 8.143t-3.753 10.266q0 5.947 4.248 9.841t11.045 3.894q4.39 0 7.293-1.274t4.46-3.398 2.195-4.957a26.4 26.4 0 0 0 .637-5.805q0-5.24 2.974-8.921 2.973-3.681 10.62-3.682 6.513 0 10.408 4.248t3.894 14.444v10.478l-3.54.85a596 596 0 0 0-13.17 4.177 164 164 0 0 0-12.814 4.815q-6.16 2.62-11.541 5.734-5.38 3.115-9.416 7.08-4.036 3.966-6.373 8.921-2.336 4.956-2.336 11.045 0 5.947 2.195 10.974a25 25 0 0 0 6.301 8.709q4.106 3.681 9.983 5.806 5.876 2.124 13.24 2.124 5.38 0 9.345-.78 3.965-.778 7.151-2.194t5.735-3.328q2.55-1.91 5.24-4.177v8.496z",
          ),
        ]),
      ]),
      svg.g(
        [
          attribute.attribute("transform", "matrix(1.25 0 0 -1.25 0 258.84)"),
          attribute.attribute("stroke-width", "3.07"),
        ],
        [
          svg.circle([
            attribute.attribute("stroke", "#4063d8"),
            attribute.attribute("fill", "#6682df"),
            attribute.attribute("r", "16"),
            attribute.attribute("cy", "149.57"),
            attribute.attribute("cx", "48.842"),
          ]),
          svg.circle([
            attribute.attribute("stroke", "#cb3c33"),
            attribute.attribute("fill", "#d5635c"),
            attribute.attribute("r", "16"),
            attribute.attribute("cy", "149.57"),
            attribute.attribute("cx", "211.131"),
          ]),
          svg.circle([
            attribute.attribute("stroke", "#389826"),
            attribute.attribute("fill", "#60ad51"),
            attribute.attribute("r", "16"),
            attribute.attribute("cy", "185.57"),
            attribute.attribute("cx", "232.131"),
          ]),
          svg.circle([
            attribute.attribute("stroke", "#9558b2"),
            attribute.attribute("fill", "#aa79c1"),
            attribute.attribute("r", "16"),
            attribute.attribute("cy", "149.57"),
            attribute.attribute("cx", "253.131"),
          ]),
        ],
      ),
    ],
  )
}

pub fn kotlin() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 500 500"),
      attribute.attribute("space", "preserve"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.linear_gradient(
        [
          attribute.attribute("gradientUnits", "userSpaceOnUse"),
          attribute.attribute(
            "gradientTransform",
            "translate(.097 -578.99)scale(.9998)",
          ),
          attribute.attribute("y2", "1079.206"),
          attribute.attribute("y1", "579.106"),
          attribute.attribute("x2", "-.097"),
          attribute.attribute("x1", "500.003"),
          attribute.id("kotlinGradient"),
        ],
        [
          svg.stop([
            attribute.attribute("style", "stop-color:#e44857"),
            attribute.attribute("offset", ".003"),
          ]),
          svg.stop([
            attribute.attribute("style", "stop-color:#c711e1"),
            attribute.attribute("offset", ".469"),
          ]),
          svg.stop([
            attribute.attribute("style", "stop-color:#7f52ff"),
            attribute.attribute("offset", "1"),
          ]),
        ],
      ),
      svg.path([
        attribute.attribute("style", "fill:url(#kotlinGradient)"),
        attribute.attribute("d", "M500 500H0V0h500L250 250z"),
      ]),
    ],
  )
}

pub fn lua() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 256"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M225.85 128.024c0-54.024-43.846-97.87-97.87-97.87-54.023 0-97.869 43.846-97.869 97.87 0 54.023 43.846 97.869 97.87 97.869 54.023 0 97.869-43.846 97.869-97.87",
        ),
        attribute.attribute("fill", "#00007D"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M197.195 87.475c0-15.823-12.842-28.666-28.665-28.666s-28.666 12.843-28.666 28.666 12.843 28.665 28.666 28.665 28.665-12.842 28.665-28.665",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M254.515 30.154c0-15.823-12.842-28.665-28.665-28.665s-28.665 12.842-28.665 28.665c0 15.824 12.842 28.666 28.665 28.666s28.665-12.842 28.665-28.666",
        ),
        attribute.attribute("fill", "#00007D"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M61.25 113.756h8.559v55.654h31.697v7.526H61.25zM116.946 130.874v30.579q0 3.527 1.09 5.763 2.01 4.13 7.497 4.13 7.875-.001 10.723-7.226 1.55-3.871 1.55-10.624v-22.622h7.74v46.062h-7.31l.086-6.795q-1.478 2.623-3.674 4.43-4.346 3.612-10.55 3.613-9.665 0-13.166-6.581-1.9-3.525-1.9-9.419v-31.31zM182.88 149.06q2.665-.343 3.57-2.233.514-1.035.515-2.979 0-3.971-2.812-5.763t-8.047-1.792q-6.053 0-8.585 3.285-1.417 1.816-1.846 5.403h-7.225q.215-8.54 5.52-11.883t12.307-3.342q8.119 0 13.188 3.096 5.026 3.097 5.026 9.635v26.538q0 1.204.495 1.934.494.73 2.086.73.516 0 1.16-.064.647-.064 1.377-.193v5.72q-1.807.515-2.752.644-.947.13-2.58.13-4 0-5.807-2.839-.946-1.505-1.333-4.257-2.367 3.097-6.796 5.376-4.43 2.278-9.763 2.278-6.409 0-10.472-3.887-4.065-3.887-4.065-9.73 0-6.4 4-9.922t10.494-4.34zm-16.302 20.913q2.452 1.932 5.807 1.931 4.084 0 7.913-1.889 6.451-3.134 6.451-10.263v-6.226q-1.416.906-3.648 1.51t-4.378.861l-4.679.602q-4.206.558-6.326 1.76-3.59 2.017-3.59 6.436 0 3.347 2.45 5.278",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m132.532 255.926-.102-2.935c3.628-.127 7.287-.413 10.873-.85l.356 2.914c-3.67.448-7.414.74-11.127.87m-11.162-.09c-3.707-.19-7.445-.545-11.111-1.054l.403-2.908c3.582.497 7.236.843 10.858 1.029zm33.3-2.618-.61-2.872c3.545-.752 7.097-1.67 10.559-2.73l.86 2.807a128 128 0 0 1-10.81 2.795m-55.39-.454c-3.613-.829-7.233-1.83-10.761-2.973l.905-2.793a125 125 0 0 0 10.512 2.904zM176 246.69l-1.103-2.721a125 125 0 0 0 9.916-4.533l1.336 2.615A128 128 0 0 1 176 246.69m-97.945-.809a128 128 0 0 1-10.079-4.811l1.38-2.592c3.2 1.704 6.514 3.285 9.847 4.7zm117.802-9.34-1.56-2.488a126 126 0 0 0 8.982-6.19l1.77 2.343a129 129 0 0 1-9.192 6.334m-137.5-1.144a129 129 0 0 1-9.088-6.487l1.808-2.314a126 126 0 0 0 8.88 6.34zm155.3-12.299-1.966-2.18c2.692-2.427 5.31-5 7.78-7.649l2.147 2.003a130 130 0 0 1-7.962 7.826M40.777 221.66a129 129 0 0 1-7.83-7.958l2.18-1.966a127 127 0 0 0 7.652 7.776zm188.094-14.876-2.313-1.808a126 126 0 0 0 6.343-8.878l2.461 1.602a129 129 0 0 1-6.491 9.084m-203.037-1.686a129 129 0 0 1-6.338-9.189l2.487-1.56a126 126 0 0 0 6.194 8.978zm215.206-17.015-2.591-1.38c1.705-3.2 3.288-6.513 4.705-9.845l2.702 1.149a128 128 0 0 1-4.816 10.076m-227.058-1.878a128 128 0 0 1-4.645-10.148l2.72-1.104a125 125 0 0 0 4.538 9.914zm235.788-18.66-2.792-.907a125 125 0 0 0 2.91-10.51l2.861.658a128 128 0 0 1-2.979 10.759M5.6 165.537a127 127 0 0 1-2.8-10.807l2.872-.61a125 125 0 0 0 2.735 10.557zm249.175-19.73-2.908-.405c.499-3.58.847-7.233 1.033-10.857l2.933.152a129 129 0 0 1-1.058 11.11M.957 143.721a129 129 0 0 1-.876-11.127l2.935-.104c.127 3.627.416 7.285.855 10.873zm252.035-20.085c-.126-3.62-.414-7.28-.856-10.876l2.914-.358c.452 3.681.747 7.427.876 11.132zM3.098 121.581l-2.932-.148c.188-3.708.54-7.447 1.047-11.112l2.909.402c-.496 3.582-.84 7.235-1.024 10.858M250.335 102a126 126 0 0 0-2.732-10.563l2.808-.858a129 129 0 0 1 2.796 10.81zM6.088 99.996l-2.862-.656a128 128 0 0 1 2.968-10.762l2.794.905a125 125 0 0 0-2.9 10.513m237.874-18.845c-1.358-3.36-2.88-6.7-4.525-9.928l2.616-1.333a129 129 0 0 1 4.631 10.161zM12.802 79.26l-2.703-1.146a128 128 0 0 1 4.806-10.082l2.592 1.379a125 125 0 0 0-4.695 9.849m10.233-19.25-2.462-1.6a129 129 0 0 1 6.483-9.091l2.314 1.807a126 126 0 0 0-6.335 8.883m13.416-17.185-2.15-2a129 129 0 0 1 7.954-7.835l1.968 2.18a127 127 0 0 0-7.772 7.655m16.177-14.61-1.772-2.34a129 129 0 0 1 9.186-6.343l1.562 2.486a126 126 0 0 0-8.976 6.198m143.494-5.099-.16-.103 1.596-2.464.155.1zm-9.568-5.627a126 126 0 0 0-9.854-4.682l1.143-2.704a128 128 0 0 1 10.085 4.792zm-115.471-.864-1.34-2.613a128 128 0 0 1 10.146-4.65l1.105 2.72a125 125 0 0 0-9.911 4.543m95.392-7.623a126 126 0 0 0-10.517-2.9l.656-2.862c3.614.828 7.236 1.827 10.765 2.968zM91.27 8.424l-.862-2.807a128 128 0 0 1 10.806-2.805l.612 2.871a125 125 0 0 0-10.556 2.741m53.958-4.296c-3.59-.5-7.244-.846-10.862-1.03l.15-2.932c3.702.188 7.443.543 11.117 1.054zm-32.646-.249-.36-2.914c3.67-.452 7.414-.748 11.127-.881l.105 2.934c-3.629.13-7.286.42-10.872.861",
        ),
        attribute.attribute("fill", "#929292"),
      ]),
    ],
  )
}

pub fn mercury() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 512 512"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M280.522 250.364c-7.11-.939-5.193-5.615-7.72-5.615s-5.053 6.317-8.282 9.967-8.843 2.667-8.843-5.194-1.685-6.176-1.685-6.176c-1.825 2.807-11.483 21.28-16.246 20.118-4.635-1.13-7.348-1.91-8.14-4.522 0 0-8.705 6.897-15.488 11.758-6.213 4.452-11.54 3.043-11.54 3.043 0-4.949 3.967-15.549-.254-12.943-10.376 6.409-30.257 20.037-28.676 12.055 2.665-13.45 2.356-17.964 2.356-17.964-12.055 8.5-30.756 11.592-34.002 11.747-3.245.154-10.973-4.637 2.937-14.528s12.055-12.056 11.746-14.838c-.31-2.782-13.292 2.473-23.338 3.091-2.794.172-24.42-1.081-10.51-6.8s31.058-21.447 31.058-21.447c-22.052 13.57-45.8 9.45-52.342 5.573s-.242-5.088-.242-5.088c42.164-6.785 42.164-14.54 42.164-14.54-49.919 11.39-60.58 4.12-69.547-2.423s-.242-7.512-.242-7.512c54.038.485 71.97-11.632 71.97-11.632l-3.615-.747c-37.305 8.695-78.816 4.488-88.353-3.085s3.366-9.536 3.366-9.536c62.268 5.89 93.682-7.013 93.682-7.013s-53.012-.28-79.097-1.963-45.719-15.988-48.243-21.597 7.292-3.366 7.292-3.366c16.064 2.94 27.224 6.65 38.988 8.134 57.78 7.292 71.804-2.525 71.804-2.525s-1.963 0-15.707 1.403c-13.744 1.402-15.146-5.049-15.146-5.049-24.465 1.494-33.332-1.485-70.102-14.345C2.615 103.545 0 94.768 0 92.153s12.92-1.42 12.92-1.42c37.359 16.714 120.413 28.076 133.522 24.143s-.8-3.824-.8-3.824-33.787-1.6-70.039-10.485C42.436 92.438 14.526 81.049 3.738 70.679c-10.218-9.821 5.25-9.111 13.77-8.128s86.515 30.477 148.263 32.794c11.326 1.506 12.232.197 12.232.197-11.211-2.623-32.145-3.864-40.329-9.913s-6.387-14.707-1.27-10.888c13.02 9.716 47.613 14.464 47.613 14.464 37.361 2.491 51.643-5.823 77.924 8.54 20.813 11.375 13.893 25.315 11.77 38.643-5.422 34.04 2.47 50.39 14.046 63.437 13.53 15.25 30.76 18.899 30.76 18.899 8.895 1.779 7.828 8.183 2.846 10.674 0 0-33.401 21.949-40.84 20.966m-17.394-110.05s7.406-18.662-4.938-31.005c-10.861-10.861-28.136-8.222-28.136-8.222-1.574.524-1.328 2.17.489 2.298 0 0 15.206 1.185 22.71 10.466s8.69 21.724 8.69 24.686 1.185 1.777 1.185 1.777m123.509 47.97c21.254-13.792 73.032-12.888 73.032-12.888-72.467-45.13-126.167-38.89-171.473-40.094 11.343 1.152 82.692 32.199 98.44 52.982m-65.601 147.242s-16.363-10.698-25.313-24.179c-4.236-6.382-4.85-16.16-4.91-20.59-.187-13.583 10.389-17.19 16.433-16.056 7.22 1.354 15.595 8.48 15.595 8.48-3.694-18.492 2.818-24.12 55.998-23.403 8.977.121 16.245-1.889 29.492 6.713l29.509 19.094 41.893-9.59c-.809 16.802 7.977 48.393 7.977 48.393.557 2.957 2.551 5.891-3.013 7.495-2.165.623-5.415 1.668-8.342 2.228a8.54 8.54 0 0 0-6.821 7.068l-2.444 15.529h-20.577v6.01c1.82 1.895 10.145 4.117 13.966 3.606 6.16-.823 5.616 7.978 3.698 8.764s-5.704.073-7.785 1.784c-.85.699-2.35 2.533-2.27 4.703.114 3.14 2.19 6.982 3.08 9.083 3.66 8.633 8.279 21.464.071 25.352-4.64 2.198-18.52.436-29.851-1.002-41.071-5.209-76.933-41.508-77.935-43.312s-5.61-6.574-5.61-6.574c7.012 52.892 38.372 58.073 48.203 61.514-7.62 11.552-8.11 23.35-8.11 23.35 5.946-8.261 14.032-11.85 33.96-18.656 4.627-1.58 8.586-1.89 12.328-1.908 33.914-.165 36.882-13.824 38.998-18.762 2.212-5.16.245-21.383-1.721-25.07-1.966-3.686 6.145-9.585 6.145-9.585v-11.06c0-1.229 1.966-2.704 3.686-4.916s-.082-17.286-.082-17.286 21.73 2.239 20.747-7.265-8.294-23.868-9.932-31.077c-1.639-7.21 4.588-40.309 4.588-40.309 23.267-15.074 19.007-78.978 19.007-78.978-79.306 7.21-132.886 29.166-158.94 39.98-26.052 10.815-44.848 25.654-82.207 52.69-51.252 37.09-92.298 74.135-92.298 74.135s-14.747 15.73-9.831 27.036 11.306 11.306 11.306 11.306 60.462-78.16 101.262-89.957c18.642 34.214 28.846 32.595 40.05 35.222",
        ),
        attribute.attribute("fill", "#666"),
      ]),
    ],
  )
}

pub fn nim() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 290 201"),
      attribute.attribute("data-name", "nim-crown"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute("style", "fill:#ffe953"),
        attribute.attribute(
          "d",
          "M217 126.5c-10.4 5.3-25 7.5-25 7.5l-47-27.5L98 134s-14.6-2.2-25-7.5c-15.8-8.5-33-29.7-38-38 0 0 13.1 36.6 22 62 19.2 29.9 53.4 45.4 88 45.5 34.6-.1 68.8-15.6 88-45.5 8.9-25.4 22-62 22-62-5 8.3-22.2 29.5-38 38",
        ),
      ]),
      svg.path([
        attribute.attribute("style", "fill:#f3d400"),
        attribute.attribute(
          "d",
          "M250 50c-4.3-4.6-10.5-8.7-18-12.5-4.7-9-12.5-25-12.5-25s-7.8 7.3-17 14.2c-11.8-2.9-25.1-4.7-39.2-5.7C154.1 12.6 145 3.8 145 3.8s-9.1 8.8-18.3 17.2c-14.1 1-27.4 2.8-39.2 5.7-9.2-6.9-17-14.2-17-14.2s-7.8 16-12.5 25c-7.5 3.8-13.7 7.9-18 12.5-6.8-3.2-15-7-15-7 9 21.5 15.5 43.1 32 56 13.2-24.7 50.5-36 88-35.3 37.5-.7 74.8 10.6 88 35.3 16.5-12.9 23-34.5 32-56 0 0-8.2 3.8-15 7",
        ),
      ]),
    ],
  )
}

pub fn nix() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 501.704 435.14"),
      attribute.attribute("xlink", "http://www.w3.org/1999/xlink"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.defs([], [
        svg.linear_gradient([attribute.id("nixGradientD")], [
          svg.stop([
            attribute.attribute("style", "stop-color:#699ad7;stop-opacity:1"),
            attribute.attribute("offset", "0"),
          ]),
          svg.stop([
            attribute.attribute("style", "stop-color:#7eb1dd;stop-opacity:1"),
            attribute.attribute("offset", ".243"),
          ]),
          svg.stop([
            attribute.attribute("style", "stop-color:#7ebae4;stop-opacity:1"),
            attribute.attribute("offset", "1"),
          ]),
        ]),
        svg.linear_gradient([attribute.id("nixGradientC")], [
          svg.stop([
            attribute.attribute("style", "stop-color:#415e9a;stop-opacity:1"),
            attribute.attribute("offset", "0"),
          ]),
          svg.stop([
            attribute.attribute("style", "stop-color:#4a6baf;stop-opacity:1"),
            attribute.attribute("offset", ".232"),
          ]),
          svg.stop([
            attribute.attribute("style", "stop-color:#5277c3;stop-opacity:1"),
            attribute.attribute("offset", "1"),
          ]),
        ]),
        svg.linear_gradient(
          [
            attribute.attribute("gradientUnits", "userSpaceOnUse"),
            attribute.attribute(
              "gradientTransform",
              "translate(70.65 -1055.151)",
            ),
            attribute.attribute("y2", "506.188"),
            attribute.attribute("y1", "351.411"),
            attribute.attribute("x2", "290.087"),
            attribute.attribute("x1", "200.597"),
            attribute.href("#nixGradientD"),
            attribute.id("nixGradientG"),
          ],
          [],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("gradientUnits", "userSpaceOnUse"),
            attribute.attribute(
              "gradientTransform",
              "translate(864.696 -1491.34)",
            ),
            attribute.attribute("y2", "937.714"),
            attribute.attribute("y1", "782.336"),
            attribute.attribute("x2", "-496.297"),
            attribute.attribute("x1", "-584.199"),
            attribute.href("#nixGradientC"),
            attribute.id("nixGradientI"),
          ],
          [],
        ),
      ]),
      svg.g([attribute.attribute("style", "display:inline")], [
        svg.path([
          attribute.attribute("transform", "translate(-156.339 933.19)"),
          attribute.attribute(
            "style",
            "color:#000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000;solid-opacity:1;fill:#5277c3;fill-opacity:1;fill-rule:evenodd;stroke:none;stroke-width:3;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto",
          ),
          attribute.attribute(
            "d",
            "M309.404-710.252 431.6-498.577l-56.157.527-32.623-56.87-32.857 56.566-27.902-.011-14.29-24.69 46.81-80.49-33.23-57.826z",
          ),
        ]),
        svg.path([
          attribute.attribute("transform", "translate(-156.339 933.19)"),
          attribute.attribute(
            "style",
            "color:#000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000;solid-opacity:1;fill:#7ebae4;fill-opacity:1;fill-rule:evenodd;stroke:none;stroke-width:3;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto",
          ),
          attribute.attribute(
            "d",
            "M353.51-797.443 231.291-585.78l-28.535-48.37 32.938-56.688-65.415-.172-13.941-24.17 14.236-24.72 93.112.293 33.464-57.69zM362.885-628.243l244.415.012-27.623 48.897-65.562-.182 32.56 56.737-13.962 24.159-28.527.032-46.301-80.784-66.693-.136zM505.143-720.989 382.946-932.664l56.157-.527 32.624 56.87 32.856-56.566 27.903.011 14.29 24.69-46.81 80.49 33.23 57.826z",
          ),
        ]),
        svg.path([
          attribute.attribute("transform", "translate(-156.339 933.19)"),
          attribute.attribute(
            "style",
            "color:#000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000;solid-opacity:1;fill:#5277c3;fill-opacity:1;fill-rule:evenodd;stroke:none;stroke-width:3;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto",
          ),
          attribute.attribute(
            "d",
            "M309.404-710.252 431.6-498.577l-56.157.527-32.623-56.87-32.857 56.566-27.902-.011-14.29-24.69 46.81-80.49-33.23-57.826zM451.336-803.533l-244.414-.012 27.622-48.896 65.562.181-32.558-56.737 13.96-24.158 28.528-.032 46.301 80.784 66.693.135zM460.872-633.842l122.217-211.664 28.535 48.37-32.938 56.688 65.415.172 13.941 24.17-14.236 24.72-93.112-.293-33.464 57.69z",
          ),
        ]),
      ]),
      svg.g(
        [
          attribute.attribute("transform", "translate(-156.339 933.19)"),
          attribute.attribute("style", "display:inline;opacity:1"),
        ],
        [
          svg.path([
            attribute.attribute(
              "style",
              "opacity:1;fill:url(#nixGradientG);fill-opacity:1;fill-rule:evenodd;stroke:none;stroke-width:3;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "m309.549-710.388 122.197 211.675-56.157.527-32.624-56.87-32.856 56.566-27.903-.011-14.29-24.69 46.81-80.49-33.23-57.826z",
            ),
            attribute.id("nixPathH"),
          ]),
          svg.use_([
            attribute.attribute("transform", "rotate(60 407.112 -715.787)"),
            attribute.attribute("height", "100%"),
            attribute.attribute("width", "100%"),
            attribute.href("#nixPathH"),
          ]),
          svg.use_([
            attribute.attribute("transform", "rotate(-60 407.312 -715.7)"),
            attribute.attribute("height", "100%"),
            attribute.attribute("width", "100%"),
            attribute.href("#nixPathH"),
          ]),
          svg.use_([
            attribute.attribute("transform", "rotate(180 407.419 -715.756)"),
            attribute.attribute("height", "100%"),
            attribute.attribute("width", "100%"),
            attribute.href("#nixPathH"),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "color:#000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000;solid-opacity:1;fill:url(#nixGradientI);fill-opacity:1;fill-rule:evenodd;stroke:none;stroke-width:3;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto",
            ),
            attribute.attribute(
              "d",
              "m309.549-710.388 122.197 211.675-56.157.527-32.624-56.87-32.856 56.566-27.903-.011-14.29-24.69 46.81-80.49-33.23-57.826z",
            ),
            attribute.id("nixPathJ"),
          ]),
          svg.use_([
            attribute.attribute("transform", "rotate(120 407.34 -716.084)"),
            attribute.attribute("style", "display:inline"),
            attribute.attribute("height", "100%"),
            attribute.attribute("width", "100%"),
            attribute.href("#nixPathJ"),
          ]),
          svg.use_([
            attribute.attribute("transform", "rotate(-120 407.288 -715.87)"),
            attribute.attribute("style", "display:inline"),
            attribute.attribute("height", "100%"),
            attribute.attribute("width", "100%"),
            attribute.href("#nixPathJ"),
          ]),
        ],
      ),
    ],
  )
}

pub fn ocaml() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 512 141"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.defs([], [
        svg.linear_gradient(
          [
            attribute.attribute("y2", "100%"),
            attribute.attribute("y1", "0%"),
            attribute.attribute("x2", "50%"),
            attribute.attribute("x1", "50%"),
            attribute.id("ocamlGradient1"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#F29100"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#EC670F"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "100%"),
            attribute.attribute("y1", "0%"),
            attribute.attribute("x2", "50%"),
            attribute.attribute("x1", "50%"),
            attribute.id("ocamlGradient2"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#F29100"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#EC670F"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "99.999%"),
            attribute.attribute("y1", "0%"),
            attribute.attribute("x2", "50%"),
            attribute.attribute("x1", "50%"),
            attribute.id("ocamlGradient3"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#F29100"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#EC670F"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M83.953 123.855c-.203-1.389.192-2.77-.226-4.073-.358-1.137-1.179-1.242-1.718-2.166-1.421-2.426-2.89-5.568-3.025-8.538-.124-2.667-1.105-5.077-1.239-7.72-.064-1.276.086-2.592.04-3.855a12 12 0 0 0-.181-1.814c-.03-.164-.14-.843-.19-1.115l.331-.827c-.146-.284 2.83-.19 3.718-.184 1.506.019 2.923.097 4.426.17 3.07.151 5.867.113 8.857-.348 6.663-1.029 9.726-3.75 11.294-4.881 6.117-4.411 8.92-11.623 8.92-11.623 1.008-2.253 1.005-6.272 3.169-8.071 2.55-2.125 6.832-1.972 9.76-3.276 1.712-.758 2.948-1.175 4.699-.812 1.299.27 3.637 1.776 4.175-.337-.434-.28-.604-.792-.836-1.075 2.413-.24.046-5.838-.91-6.957-1.474-1.726-3.934-2.517-6.552-3.211-3.109-.824-5.93-1.775-8.857-1.2-5.112 1-4.73-1.926-7.742-1.926-3.616 0-10.048.178-11.16 3.692-.518 1.642-1.051 1.71-1.949 2.969-.767 1.079.134 2.03-.251 3.261-.398 1.265-.982 5.72-1.592 7.274-1.03 2.63-2.26 5.915-4.528 5.915-3.18.38-5.68.503-8.259-.434-1.553-.563-4.155-1.446-5.442-1.988-5.937-2.5-6.912-5.234-6.912-5.234-.637-1.054-2.316-2.751-2.944-4.967-.69-2.44-1.855-4.476-2.328-5.745-.488-1.316-1.656-3.423-2.574-5.702-1.175-2.917-2.828-5.093-4.039-6.174-1.849-1.648-3.555-4.2-7.309-3.458-.671.133-3.11.243-4.978 1.81-1.266 1.063-1.666 3.256-2.84 5.106-.677 1.07-1.87 4.135-2.962 6.693-.758 1.773-1.111 3.103-1.93 3.755-.641.511-1.435 1.171-2.395.811-.596-.223-1.233-.601-1.876-1.103-.868-.678-2.84-4.036-4.053-6.516-1.05-2.15-3.292-5.366-4.59-7.107-1.866-2.504-2.96-3.139-5.718-3.139-5.917 0-6.365 3.313-8.968 8.13-1.143 2.117-1.559 5.476-3.854 8.108-1.311 1.506-5.497 7.697-8.407 8.75v-.03l-.008.03v44.136l.008.061v-.277c.188-.575.388-1.127.615-1.62 1.126-2.398 3.737-4.624 5.188-7.086.79-1.342 1.69-2.657 2.212-4.065.45-1.213.671-3.023 1.32-4.075.797-1.29 2.043-1.729 3.322-1.938 2.005-.33 3.707 2.881 6.271 4.063 1.093.503 6.126 2.284 7.636 2.65 2.488.595 5.248 1.091 7.774 1.601 1.353.273 2.646.432 4.038.574 1.25.125 5.93.28 6.22.618-2.38 1.213-3.774 4.619-4.667 7.029-.931 2.51-1.58 5.306-2.706 7.762-1.248 2.715-3.863 3.844-3.551 7.007.12 1.262.35 2.585.14 3.974-.225 1.462-.816 2.603-1.246 4.034-.552 1.868-1.21 7.9-2.06 9.673l5.204-.653.009-.003c.568-1.351 1.092-7.057 1.276-7.6.974-2.862 2.265-5.216 4.252-7.43 1.936-2.155 1.836-4.935 2.967-7.447 1.225-2.73 2.872-4.914 4.427-7.481 2.81-4.641 4.662-10.5 10.636-11.692.638-.132 4.295 2.505 5.917 4.073 1.86 1.787 3.89 3.857 5.11 6.32 2.365 4.775 4.37 11.691 5.129 15.505.435 2.19.783 2.321 2.264 4.056.682.795 2.042 3.279 2.49 4.233.47 1.018 1.185 3.335 1.754 4.518.336.704 1.206 2.867 1.839 4.736l4.863-.152c.018.04.106-.012.127.026l.007-.002c-.02-.037-.04-.08-.057-.12-2.423-4.863-3.974-10.49-4.775-15.876",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M81.95 135.24c-.57-1.183-1.283-3.5-1.754-4.518-.448-.954-1.808-3.437-2.49-4.233-1.482-1.735-1.829-1.865-2.265-4.056-.757-3.814-2.763-10.731-5.127-15.505-1.221-2.463-3.252-4.533-5.11-6.32-1.623-1.567-5.28-4.205-5.918-4.073-5.974 1.193-7.827 7.05-10.636 11.692-1.555 2.567-3.202 4.75-4.427 7.481-1.131 2.511-1.03 5.292-2.968 7.448-1.986 2.214-3.277 4.568-4.25 7.428-.185.544-.709 6.25-1.277 7.601l-.001.003 8.878-.625c8.272.564 5.884 3.734 18.796 3.044l20.389-.631c-.634-1.869-1.504-4.032-1.84-4.736",
        ),
        attribute.attribute("fill", "url(#ocamlGradient1)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M141.112 0H20.348C9.116 0 .01 9.108.01 20.34v44.38c2.91-1.052 7.096-7.243 8.407-8.75 2.295-2.632 2.711-5.991 3.854-8.106 2.603-4.818 3.051-8.13 8.968-8.13 2.758 0 3.853.635 5.719 3.138 1.298 1.741 3.54 4.958 4.589 7.107 1.211 2.481 3.185 5.838 4.053 6.516.643.503 1.28.88 1.875 1.104.96.36 1.754-.3 2.396-.812.819-.652 1.172-1.982 1.93-3.755 1.094-2.558 2.285-5.623 2.962-6.693 1.174-1.849 1.573-4.043 2.84-5.106 1.869-1.567 4.307-1.677 4.978-1.81 3.754-.741 5.46 1.81 7.31 3.458 1.21 1.08 2.864 3.258 4.038 6.174.918 2.279 2.086 4.386 2.574 5.702.472 1.27 1.638 3.305 2.328 5.745.627 2.216 2.306 3.913 2.944 4.967 0 0 .976 2.734 6.912 5.234 1.287.542 3.89 1.424 5.442 1.988 2.58.938 5.078.816 8.26.434 2.268 0 3.496-3.284 4.527-5.915.61-1.554 1.194-6.009 1.592-7.274.385-1.23-.516-2.182.251-3.261.898-1.259 1.431-1.327 1.949-2.969 1.113-3.514 7.544-3.692 11.16-3.692 3.013 0 2.63 2.926 7.742 1.925 2.928-.574 5.75.378 8.857 1.2 2.618.695 5.078 1.486 6.553 3.212.955 1.118 3.321 6.718.909 6.957.232.283.401.795.835 1.075-.537 2.113-2.876.608-4.175.337-1.75-.363-2.986.054-4.698.812-2.928 1.304-7.21 1.152-9.76 3.276-2.164 1.8-2.16 5.82-3.17 8.071 0 0-2.802 7.21-8.92 11.623-1.567 1.131-4.63 3.852-11.293 4.88-2.99.463-5.787.501-8.857.348-1.503-.072-2.92-.15-4.426-.169-.888-.006-3.865-.101-3.718.184l-.332.827c.052.272.16.952.19 1.115.122.668.157 1.201.182 1.814.046 1.263-.104 2.58-.04 3.855.134 2.643 1.115 5.053 1.239 7.72.135 2.97 1.604 6.112 3.025 8.538.539.923 1.36 1.029 1.718 2.166.42 1.303.022 2.685.226 4.073.8 5.385 2.35 11.013 4.775 15.872a1 1 0 0 0 .058.122c2.994-.503 5.993-1.58 9.884-2.155 7.133-1.058 17.053-.513 23.425-1.11 16.123-1.515 24.874 6.613 39.356 3.282V20.342C161.45 9.108 152.348 0 141.113 0M80.866 95.477c-.023-.244-.012-.21.022-.06z",
        ),
        attribute.attribute("fill", "url(#ocamlGradient2)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M37.23 114.155c1.125-2.456 1.775-5.252 2.706-7.763.893-2.41 2.288-5.816 4.667-7.029-.29-.338-4.97-.493-6.22-.618-1.392-.142-2.685-.3-4.038-.574-2.526-.51-5.286-1.005-7.774-1.601-1.51-.366-6.543-2.147-7.636-2.65-2.564-1.182-4.266-4.393-6.27-4.063-1.28.21-2.526.648-3.322 1.938-.65 1.053-.871 2.86-1.32 4.075-.522 1.408-1.424 2.723-2.213 4.065-1.45 2.461-4.062 4.688-5.188 7.086a16 16 0 0 0-.615 1.62v27.418c1.312.224 2.686.5 4.223.91 11.343 3.027 14.11 3.283 25.236 2.011l1.043-.138v-.001c.852-1.773 1.509-7.805 2.061-9.673.43-1.431 1.021-2.572 1.245-4.034.212-1.389-.02-2.712-.14-3.974-.308-3.162 2.307-4.291 3.555-7.005",
        ),
        attribute.attribute("fill", "url(#ocamlGradient3)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M212.944 122.689q-8.055 0-14.706-2.868c-4.437-1.91-8.238-4.656-11.412-8.238q-4.76-5.37-7.382-13.059-2.625-7.687-2.625-17.452t2.625-17.39q2.622-7.627 7.382-12.816c3.174-3.457 6.975-6.102 11.412-7.932q6.652-2.746 14.706-2.746t14.707 2.746q6.648 2.747 11.41 7.994 4.758 5.25 7.384 12.876 2.622 7.63 2.622 17.269 0 9.765-2.622 17.452-2.625 7.69-7.385 13.059-4.76 5.372-11.41 8.238-6.652 2.866-14.706 2.867m0-15.5q8.176 0 12.938-7.017 4.757-7.018 4.758-19.1 0-11.96-4.758-18.672-4.762-6.712-12.938-6.713-8.177 0-12.937 6.713t-4.76 18.672q0 12.082 4.76 19.1 4.762 7.017 12.937 7.016M255.413 81.926q0-9.885 3.051-17.635t8.238-13.12a35 35 0 0 1 12.082-8.178q6.896-2.806 14.585-2.807 7.443 0 13.486 3.112 6.04 3.113 10.068 7.261l-9.886 11.106q-3.051-2.805-6.163-4.393-3.112-1.586-7.261-1.587-4.151 0-7.75 1.77t-6.284 5.064q-2.686 3.293-4.21 8.054-1.526 4.761-1.526 10.74 0 12.327 5.25 19.1 5.244 6.773 14.034 6.772 4.88 0 8.543-1.952 3.66-1.951 6.591-5.126l9.886 10.862q-5.005 5.858-11.411 8.787-6.41 2.93-13.853 2.93-7.688 0-14.523-2.623-6.836-2.625-11.96-7.75-5.126-5.126-8.056-12.754-2.931-7.623-2.931-17.633M324.123 104.382q0-9.52 8.054-14.89 8.056-5.369 25.996-7.2-.246-4.027-2.44-6.407-2.199-2.38-7.08-2.38-3.906.001-7.81 1.465-3.909 1.466-8.3 4.028l-6.346-11.838a63.5 63.5 0 0 1 12.264-5.737c4.273-1.463 8.806-2.196 13.608-2.196q11.716 0 17.88 6.651c4.106 4.436 6.163 11.33 6.163 20.687v34.66h-14.644l-1.343-6.224h-.366q-3.907 3.418-8.237 5.552-4.334 2.135-9.46 2.136-4.148-.001-7.443-1.404-3.295-1.402-5.614-3.905-2.319-2.501-3.601-5.797-1.28-3.295-1.28-7.201m17.086-1.343q0 2.93 1.891 4.332 1.891 1.404 5.065 1.403 3.172.001 5.37-1.342 2.196-1.342 4.638-3.784V93.03q-9.642 1.343-13.303 3.906-3.66 2.565-3.66 6.103M386.608 60.69h14.646l1.22 7.81h.489q3.78-3.781 8.055-6.528 4.272-2.747 10.252-2.747 6.468 0 10.434 2.624t6.285 7.505c2.686-2.765 5.51-5.144 8.482-7.14q4.453-2.989 10.558-2.99 9.76.001 14.339 6.53 4.576 6.529 4.576 17.879v37.59h-17.94V85.951q0-6.59-1.77-9.032-1.77-2.44-5.673-2.441-4.517 0-10.376 5.858v40.885h-17.938v-35.27q-.002-6.59-1.77-9.032-1.77-2.44-5.676-2.441-4.64 0-10.252 5.858v40.885h-17.941zM486.318 35.671h17.942v67.49q0 2.808 1.035 3.906 1.038 1.098 2.137 1.098h1.036q.426.001 1.16-.244l2.195 13.303q-1.463.61-3.721 1.037-2.26.427-5.308.428-4.641 0-7.812-1.465-3.173-1.463-5.064-4.088-1.893-2.623-2.747-6.346-.854-3.721-.853-8.36z",
        ),
        attribute.attribute("fill", "#484444"),
      ]),
    ],
  )
}

pub fn pascal() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 341 341"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.ellipse([
        attribute.attribute("ry", "22.2"),
        attribute.attribute("rx", "38.6"),
        attribute.attribute("stroke", "#fff"),
        attribute.attribute("fill", "#fff"),
        attribute.attribute("cy", "106.6"),
        attribute.attribute("cx", "105"),
      ]),
      svg.ellipse([
        attribute.attribute("ry", "22.9"),
        attribute.attribute("rx", "43.4"),
        attribute.attribute("stroke", "#fff"),
        attribute.attribute("fill", "#fff"),
        attribute.attribute("cy", "113.1"),
        attribute.attribute("cx", "237.2"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M156 337c-28-4-40-14-40-35 0-30-25-48-53-37-10 4-17 4-22 0l-5-2c-10 0-31-40-29-55 1-8 4-11 15-17 28-16 32-55 8-74-17-13-16-25 3-51 16-19 25-22 43-11 14 8 25 8 40 1 19-9 24-15 27-34 4-18 9-21 32-21 38 0 44 5 47 40 3 25 33 41 59 32 22-7 40 7 47 39 6 29 6 29-15 41-11 6-18 18-19 35-1 13-1 15 13 28 11 11 12 12 12 17l1 9c4 12-22 49-34 49l-16-7c-30-15-67 1-73 32-5 21-12 25-41 21m79-219c6-2 11-6 10-10 0-5-7-5-11-1-3 3-6 3-9 0l-3-3-3 3-2 4 5 5c6 4 6 5 13 2m-123-4c6-4 7-7 3-11-3-2-3-2-5 1s-7 4-10 1c-2-2-2-3 2-4l-6-1-9 1c0 11 16 19 25 13",
        ),
        attribute.attribute("fill", "#eaf1f8"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M163 338c-33-3-46-13-47-36-1-32-24-48-54-37-20 7-34-2-47-29-12-25-11-36 7-45 28-16 33-53 8-74-17-14-17-24 3-50 16-20 23-23 42-12 29 15 63 0 68-30 3-22 13-27 43-24 29 4 34 8 36 40l1 10 9 9c16 16 31 20 48 14 21-7 28-4 40 19 15 30 15 47-1 56-16 8-21 16-24 32-4 18-2 25 12 36 10 8 13 15 13 31 0 10-17 34-28 40l-7 3-14-7c-30-15-69 1-74 30-4 22-10 26-34 24m13-18c5-2 7-6 9-17 8-33 45-50 79-34 17 8 23 6 34-12 13-18 12-25-5-40-20-19-16-62 7-76 20-13 22-18 14-38-8-19-14-23-32-19-37 9-69-13-72-48-2-19-10-25-36-26-14 0-18 4-23 21-9 34-46 50-78 34-16-9-21-8-32 7-15 20-15 27 0 43 23 25 18 62-11 83-15 11-16 15-7 32 9 19 17 24 33 20 33-9 66 14 69 48 2 16 5 20 16 23 9 2 29 2 35-1m-32-10c-13-3-11-2-13-16-4-27-32-52-59-52l-10-1-5-11-9-22-4-12 6-8c12-19 14-50 4-68l-3-5 6-12 12-21 7-9 6 2c25 9 63-9 73-37l3-6h15l22 2 8 1 1 8c4 28 40 54 69 49l7-1 7 14c7 13 8 14 12 10s5-4 7 4c3 9 2 10-6 15-29 17-34 60-10 87l8 10-4 8c-5 9-16 25-19 27-2 1-5 0-12-4-30-13-72 4-81 32l-3 12-2 6h-11zm91-191c10-3 15-14 7-15-3-1-5 0-7 2-5 4-7 4-10 1-4-4-5-4-6 1-2 3-1 4 3 8 5 4 6 5 13 3m-122-5c4-4 5-5 4-8-1-4-5-5-8-2-4 3-6 3-9 1-2-2-2-3 2-4l-6-1c-11 0-12 2-7 9 7 8 17 10 24 5",
        ),
        attribute.attribute("fill", "#dde8fb"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M163 338c-33-3-46-13-47-36-2-32-24-48-53-37-21 7-34-1-47-27-13-27-12-37 6-47 29-17 33-54 8-74-16-13-16-24 1-47 17-24 24-26 44-15 30 15 62 0 68-32 4-19 9-22 32-22 38 0 45 6 47 40l1 10 9 9c16 16 31 20 48 14 21-7 28-4 40 19 15 30 15 47-2 56-18 10-24 21-24 42 0 14 1 16 14 26 9 8 12 16 12 32 0 9-18 33-28 39l-7 3-14-7c-32-16-68 1-75 35-4 17-11 21-33 19m13-18c5-2 7-6 9-17 8-33 45-50 79-34 17 8 23 6 34-12 13-18 12-23-3-38-23-24-19-66 9-81 15-9 18-16 11-34-8-20-15-24-33-20-37 9-69-12-72-47-1-19-6-23-26-26-21-3-27 1-32 17-10 37-45 53-79 37-17-9-22-7-34 10-13 20-13 24 2 41 23 24 18 61-11 82-15 11-16 15-7 32 9 19 17 24 33 20 32-8 66 14 69 47 2 15 3 18 8 21 9 5 34 6 43 2m-29-13c-15-2-15-2-16-12-2-27-32-53-60-53-9 0-9 0-7-2s2-2-4-15c-3-7-8-17-9-23l-3-10 5-8c8-16 10-42 5-56-4-9-4-9 2-21 7-17 19-31 24-30 24 5 57-11 69-32 5-10 16-11 43-6l8 1 1 8c5 23 39 47 65 45 6 0 9 3 16 19 4 10 4 10 9 6 6-4 7-4 9 5l2 6-6 4c-29 19-34 61-10 89l7 8-4 6c-5 10-15 23-19 27l-3 3-9-4c-11-5-13-5-23-5-25 0-52 18-57 37-4 16-3 15-15 15zm88-188c10-3 15-14 6-16-3 0-4 0-6 3-4 4-7 4-10 1-4-4-5-4-6 1-2 3-1 4 3 8 5 4 6 5 13 3m-122-5c4-4 5-5 4-8-1-4-5-5-8-2-4 3-6 3-9 1-2-2-2-3 2-4l-6-1c-11 0-12 2-7 9 7 8 17 10 24 5",
        ),
        attribute.attribute("fill", "#d9e6fb"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M163 338c-33-3-46-13-47-37-2-31-24-47-54-36-20 7-33-1-46-27-13-27-12-37 6-47 29-17 33-53 8-74-16-14-16-24 1-47 17-24 24-26 44-15 30 15 62 0 68-32 4-19 9-22 32-22 38 0 45 6 47 40l1 10 9 9c16 16 30 20 48 14 21-7 28-4 40 19 15 30 15 47-2 56-18 10-24 21-24 42 0 14 1 16 14 27 9 7 12 15 12 31 0 9-18 33-28 39l-7 3-14-7c-32-16-68 1-75 35-4 17-11 21-33 19m12-17c6-2 8-7 10-18 7-33 43-49 77-34 18 7 21 7 31-4 18-20 18-30 2-47a52 52 0 0 1 11-81c14-9 16-15 9-33-8-20-15-24-34-20-35 9-67-12-71-46-2-18-2-19-10-23-21-9-43-6-47 8-10 42-44 59-80 42-18-9-25-7-37 15-10 16-9 20 5 35 23 24 18 63-10 82-15 10-17 17-9 33 9 19 18 24 33 20 34-8 67 14 70 47 2 15 3 18 8 21 9 5 34 6 42 3m-16-16c-24-2-26-3-28-14-5-25-34-49-60-49h-8l4-4 4-3-5-9c-12-21-15-37-10-51 5-12 6-27 4-38-2-12-2-14 2-23 3-7 3-8 1-9-3-2 0-9 6-10l11-10c5-7 6-7 10-7 17 3 49-12 60-28 7-10 20-11 46-6l8 2 3 7c6 19 32 38 55 40 6 1 8 1 10 4l12 25c0 3 3 2 9-2l5-4 3 6c2 9 2 9-5 14-24 16-28 60-8 84 5 6 6 7 4 10-2 5-15 24-20 30l-4 4-7-3c-31-12-71 5-80 35-1 5-3 9-4 9l-4 1zm76-186c10-3 15-14 6-16-3 0-4 0-6 3-4 4-7 4-10 1-4-4-5-4-6 1-2 3-1 4 3 8 5 4 6 5 13 3m-122-5c4-4 5-5 4-8-1-4-5-5-8-2-4 3-6 3-9 1-2-2-2-3 2-4l-6-1c-11 0-12 2-7 9 7 8 17 10 24 5",
        ),
        attribute.attribute("fill", "#d3e2fa"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M163 338c-33-3-47-14-47-37 0-30-25-47-53-36-21 7-34-1-47-27-13-27-12-37 6-47 28-16 33-53 9-73-17-14-17-23-3-44 18-27 26-30 47-19 30 15 62 0 68-32 4-19 9-22 32-22 38 0 45 6 47 40l1 10 9 9c16 16 30 20 48 14 25-9 44 10 49 47l2 11c2 6-3 12-13 17-28 16-34 50-11 68 10 8 14 16 13 32 0 9-18 33-28 39l-7 3-14-7c-32-16-68 1-75 35-4 17-11 21-33 19m12-17c6-2 8-6 11-19 8-32 43-48 74-34 20 9 23 8 34-4 17-19 17-29 1-46a52 52 0 0 1 12-82c13-7 14-15 8-32-8-20-15-24-33-20-37 9-69-13-72-48-2-18-6-22-27-25-20-3-26 1-32 19a54 54 0 0 1-78 35c-18-10-27-6-39 18-7 15-7 18 7 33 23 23 18 62-10 81-27 18-7 60 25 53s69 17 69 46c0 15 4 21 15 25 8 2 29 2 35 0m-22-19-12-3-9-2-1-6c-3-24-35-50-62-50-5 0-5 0-4-1l6-5 4-3-4-7c-11-19-16-41-13-53 2-5 3-13 3-25 0-18 1-23 8-37 4-9 4-11-2-7-3 3-4 3-4-1s3-7 11-9c5-1 8-2 12-8 4-5 6-6 10-6 15 0 37-11 49-23l9-9h17c27 0 33 2 38 11 7 15 32 32 48 35 4 0 7 1 8 3l4 3c4 1 10 11 9 13-2 2 2 15 4 15l8-4 6-4 1 3c4 9 4 11-2 14-23 16-27 61-8 84l5 5-7 11a176 176 0 0 1-18 25c-1 2-2 2-8-1-30-11-68 7-78 35l-2 7zm82-183c10-3 15-14 6-16-3 0-4 0-6 3-4 4-7 4-10 1-4-4-5-4-6 1-2 3-1 4 3 8 5 4 6 5 13 3m-122-5c4-4 5-5 4-8-1-4-5-5-8-2-4 3-6 3-9 1-2-2-2-3 2-4l-6-1c-11 0-12 2-7 9 7 8 17 10 24 5",
        ),
        attribute.attribute("fill", "#cee0fa"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M163 338c-33-3-47-14-47-37 0-30-25-47-53-36-21 7-34-1-47-27-13-27-12-37 6-47 28-16 33-53 9-73-17-14-17-23-3-44 18-27 26-30 47-19 30 15 62 0 68-32 4-19 9-22 32-22 38 0 45 6 47 40l1 10 9 9c16 16 30 20 48 14 25-9 44 10 49 47l2 11c2 6-3 12-13 17-28 16-34 50-11 68 10 8 14 16 13 32 0 9-18 33-28 39l-7 3-14-7c-32-16-68 1-75 35-4 17-11 21-33 19m12-17c6-2 8-6 11-19 8-32 43-48 74-34 20 9 23 8 34-4 17-19 17-29 1-46a52 52 0 0 1 12-82c13-7 14-15 8-32-8-20-15-24-33-20-37 9-69-13-72-48-2-18-6-22-27-25-20-3-26 1-32 19a54 54 0 0 1-78 35c-18-10-27-6-39 18-7 15-7 18 7 33 23 23 18 62-10 81-27 18-7 60 25 53s69 17 69 46c0 15 4 21 15 25 8 2 29 2 35 0m-24-22c-16-3-18-4-20-13-7-21-34-42-57-44l-10-1 8-6 8-6-5-10c-17-33-17-71-2-103 6-13 3-19-6-13-3 3-4 3-4-1 0-5 9-10 20-10 3 0 6-2 11-7 5-4 8-7 13-8 10-2 28-11 34-17 12-10 63-10 68 1 5 8 24 23 37 28l11 6 9 3c4 1 13 9 13 13 0 3-5 2-9-1l-4-3 4 10 5 11c0 2 3 2 10-3 9-5 9-5 11 2l2 6-6 5c-19 17-23 58-7 79l5 6-5 9-19 26c-3 4-3 4-8 2-27-11-67 7-76 33l-3 7h-10zm84-180c10-3 15-14 6-16-3 0-4 0-6 3-4 4-7 4-10 1-4-4-5-4-6 1-2 3-1 4 3 8 5 4 6 5 13 3m-122-5c4-4 5-5 4-8-1-4-5-5-8-2-4 3-6 3-9 1-2-2-2-3 2-4l-6-1c-11 0-12 2-7 9 7 8 17 10 24 5",
        ),
        attribute.attribute("fill", "#cadcf9"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M163 338c-33-3-47-14-47-37 0-30-25-47-53-36-21 7-34-1-47-27-13-27-12-37 6-47 28-16 33-53 9-73-17-14-17-23-3-44 18-27 26-30 47-19 30 15 62 0 68-32 4-19 9-22 32-22 38 0 45 6 47 40l1 10 9 9c16 16 30 20 48 14 25-9 44 10 49 47l2 11c2 6-3 12-13 17-28 16-34 50-11 68 10 8 14 16 13 32 0 9-18 33-28 39l-7 3-14-7c-32-16-68 1-75 35-4 17-11 21-33 19m12-17c6-2 8-7 11-19 7-31 43-48 74-34 20 9 23 8 34-4 17-19 17-29 1-46a52 52 0 0 1 12-82c12-7 14-15 8-32-8-20-15-24-33-20-37 9-69-13-72-48-1-18-6-22-27-25-20-3-26 1-32 19a54 54 0 0 1-78 35c-18-10-27-6-39 18-7 15-7 18 7 32 23 24 18 63-10 82-27 18-7 60 25 53 34-7 69 17 69 46 0 15 4 21 15 25 8 2 29 2 35 0m-24-25c-10-2-18-5-19-7l-3-8c-6-16-35-38-54-39-11-1-10-2 3-11l11-7-5-10c-15-28-15-74-1-96 5-7-9-20-16-15-3 3-4 3-4-1 0-6 9-10 29-11 11 0 11 0 20-7 14-11 36-20 49-20 3 0 5-1 7-3q1.5-3 3 0l12 3c20 3 36 10 52 23 8 7 9 8 20 9 14 2 16 3 20 9 6 8 3 10-5 5-10-7-17-3-12 6l5 11 3 6 4-1c3-1 9-3 13-6 9-4 9-4 11 4 1 5 1 5-4 10-17 16-20 57-6 77l4 4-6 10c-9 16-20 29-24 28-31-8-67 8-77 35-1 4-14 5-30 2m84-177c10-3 15-14 6-16-3 0-4 0-6 3-4 4-7 4-10 1-4-4-5-4-6 1-2 3-1 4 3 8 5 4 6 5 13 3m-122-5c4-4 5-5 4-8-1-4-5-5-8-2-4 3-6 3-9 1-2-2-2-3 2-4l-6-1c-11 0-12 2-7 9 7 8 17 10 24 5",
        ),
        attribute.attribute("fill", "#c6d9f8"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M163 338c-33-3-47-14-47-37 0-30-25-47-53-36-21 7-34-1-47-27-13-27-12-37 6-47 28-16 33-53 9-73-17-14-17-23-3-44 18-27 26-30 47-19 30 15 62 0 68-32 4-19 9-22 32-22 38 0 45 6 47 40l1 10 9 9c16 16 30 20 48 14 25-9 44 10 49 47l2 11c2 6-3 12-13 17-28 16-34 50-11 68 10 8 14 16 13 32 0 9-18 33-28 39l-7 3-14-7c-32-16-68 1-75 35-4 17-11 21-33 19m12-17c6-2 8-7 11-19 7-31 43-48 74-34 20 9 23 8 34-4 17-19 17-29 1-46a52 52 0 0 1 12-82c12-7 14-15 8-32-8-20-15-24-33-20-37 9-69-13-72-48-1-18-6-22-27-25-20-3-26 1-32 19a54 54 0 0 1-78 35c-18-10-27-6-39 18-7 15-7 18 7 32 23 24 18 63-10 82-27 18-7 60 25 53 34-7 69 17 69 46 0 15 4 21 15 25 8 2 29 2 35 0m-22-29-12-2-9-2-4-8c-8-17-30-34-50-38-12-2-9-7 9-16l7-4-4-8c-15-25-16-64-3-90l3-6-4-4-7-8c-3-5-7-6-12-3-3 3-4 3-4-1 0-7 10-10 33-11 15 0 16 0 22-5 13-9 34-17 46-17 4 0 4 0 4-4l1-6c2 0 3 3 3 7 0 3 1 3 6 3 14 0 34 8 49 19 8 6 9 6 20 7 19 2 24 3 28 10 6 8 3 10-5 5-9-6-9-6-14 1l-4 6 4 8 4 9c1 1 17-4 24-7l5-3 2 7c1 6 1 6-3 11-15 17-18 48-7 70 4 8-2 22-18 40l-6 7-8-2c-21-4-55 11-65 30l-3 6h-13zm82-173c10-3 15-14 6-16-3 0-4 0-6 3-4 4-7 4-10 1-4-4-5-4-6 1-2 3-1 4 3 8 5 4 6 5 13 3m-122-5c4-4 5-5 4-8-1-4-5-5-8-2-4 3-6 3-9 1-2-2-2-3 2-4l-6-1c-11 0-12 2-7 9 7 8 17 10 24 5",
        ),
        attribute.attribute("fill", "#c5d8f6"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M163 338c-33-3-47-14-47-37 0-30-25-47-53-36-21 7-34-1-47-27-13-27-12-37 6-47 28-16 33-53 9-73-17-14-17-23-3-44 18-27 26-30 47-19 30 15 62 0 68-32 4-19 9-22 32-22 38 0 45 6 47 40l1 10 9 9c16 16 30 20 48 14 25-9 44 10 49 47l2 11c2 6-3 12-13 17-28 16-34 50-11 68 10 8 14 16 13 32 0 9-18 33-28 39l-7 3-14-7c-32-16-68 1-75 35-4 17-11 21-33 19m12-17c6-2 8-7 11-19 7-31 43-48 74-34 20 9 23 8 34-4 17-19 17-29 1-46a52 52 0 0 1 12-82c12-7 14-15 8-32-8-20-15-24-33-20-37 9-69-13-72-48-1-18-6-22-27-25-20-3-26 1-32 19a54 54 0 0 1-78 35c-18-10-27-6-39 18-7 15-7 18 7 32 23 24 18 63-10 82-27 18-7 60 25 53 34-7 69 17 69 46 0 15 4 21 15 25 8 2 29 2 35 0m-22-29-12-2-9-2-3-7c-8-18-30-35-51-39-12-2-9-7 11-17 11-5 11-5 5-17a92 92 0 0 1-5-71l5-14c1-2-1-3-3-5-3-1-7-5-10-9-6-8-9-9-14-6-4 4-7-2-2-6 6-5 36-8 46-4l5 2 9-5c10-7 20-11 33-13l10-2v-7c0-8 2-11 3-7l1 8v7h5c13 0 32 7 45 17 5 3 7 4 8 3 2-2 23-1 34 2 6 1 8 2 11 7 6 8 3 10-6 4-8-5-7-5-14 4l-7 7 2 8 4 8 6-2c8-1 18-4 24-7l5-3 2 7c1 6 1 6-3 11-14 16-17 47-8 67 4 10 4 10 2 15-4 8-13 22-19 28l-6 7-8-2c-21-4-55 11-65 30l-3 6h-13zm82-173c10-3 15-14 6-16-3 0-4 0-6 3-4 4-7 4-10 1-4-4-5-4-6 1-2 3-1 4 3 8 5 4 6 5 13 3m-122-5c4-4 5-5 4-8-1-4-5-5-8-2-4 3-6 3-9 1-2-2-2-3 2-4l-6-1c-11 0-12 2-7 9 7 8 17 10 24 5",
        ),
        attribute.attribute("fill", "#c1d5f5"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M163 338c-33-3-47-14-47-37 0-30-25-47-53-36-21 7-34-1-47-27-13-27-12-37 6-47 28-16 33-53 9-73-17-14-17-23-3-44 18-27 26-30 47-19 30 15 62 0 68-32 4-19 9-22 32-22 38 0 45 6 47 40l1 10 9 9c16 16 30 20 48 14 25-9 44 10 49 47l2 11c2 6-3 12-13 17-28 16-34 50-11 68 10 8 14 16 13 32 0 9-18 33-28 39l-7 3-14-7c-32-16-68 1-75 35-4 17-11 21-33 19m12-17c6-2 8-7 11-19 7-31 43-48 74-34 20 9 23 8 34-4 17-19 17-29 1-46a52 52 0 0 1 12-82c12-7 14-15 8-32-8-20-15-24-33-20-37 9-69-13-72-48-1-18-6-22-27-25-20-3-26 1-32 19a54 54 0 0 1-78 35c-18-10-27-6-39 18-7 15-7 18 7 32 23 24 18 63-10 82-27 18-7 60 25 53 34-7 69 17 69 46 0 15 4 21 15 25 8 2 29 2 35 0m-22-32c-16-2-22-5-25-11-7-14-25-28-43-34-11-4-13-5-13-7s14-11 20-13l5-3 3-4 3-4 2 4q1.5 3 6 3c6 0 6-1 0-9-3-5-4-5-4-3 0 3-8 7-10 5-1 0-1-5 1-11v-14c2-1 2-2 1-5-4-13-1-38 6-51 4-8 4-7-3-9-9-3-15-6-21-14s-9-9-14-6c-2 3-4 2-4-2 0-13 49-14 60 0l3 4 6-5c8-5 19-9 29-10l7-1V75l1-16c2-1 3 4 3 11l2 9c1 3 2 4 1 5-5 1-1 5 6 6 10 1 20 5 29 10 6 4 6 4 8 1l6-3 6-2c2-2 23-1 34 2 6 1 8 2 11 7 6 8 3 10-5 5-8-6-8-6-15 2-4 6-7 8-13 11l-7 3 2 5c4 7 20 7 40-1 10-4 10-4 12 5 0 4 0 6-2 8-12 13-16 47-8 65l4 7-5 10-14 21-9 11-10-1c-23-1-55 15-61 31l-2 4h-11zm82-170c10-3 15-14 6-16-3 0-4 0-6 3-4 4-7 4-10 1-4-4-5-4-6 1-2 3-1 4 3 8 5 4 6 5 13 3m-122-5c4-4 5-5 4-8-1-4-5-5-8-2-4 3-6 3-9 1-2-2-2-3 2-4l-6-1c-11 0-12 2-7 9 7 8 17 10 24 5",
        ),
        attribute.attribute("fill", "#bcd1f4"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M163 338c-33-3-47-14-47-37 0-30-25-47-53-36-21 7-34-1-47-27-13-27-12-37 6-47 28-16 33-53 9-73-17-14-17-23-3-44 18-27 26-30 47-19 30 15 62 0 68-32 4-19 9-22 32-22 38 0 45 6 47 40l1 10 9 9c16 16 30 20 48 14 25-9 44 10 49 47l2 11c2 6-3 12-13 17-28 16-34 50-11 68 10 8 14 16 13 32 0 9-18 33-28 39l-7 3-14-7c-32-16-68 1-75 35-4 17-11 21-33 19m12-17c6-2 8-7 11-19 7-31 43-48 74-34 20 9 23 8 34-4 17-19 17-29 1-46a52 52 0 0 1 12-82c12-7 14-15 8-32-8-20-15-24-33-20-37 9-69-13-72-48-1-18-6-22-27-25-20-3-26 1-32 19a54 54 0 0 1-78 35c-18-10-27-6-39 18-7 15-7 18 7 32 23 24 18 63-10 82-27 18-7 60 25 53 34-7 69 17 69 46 0 15 4 21 15 25 8 2 29 2 35 0m-20-34c-18-3-25-6-30-14-8-12-29-27-40-30-15-3-9-16 8-20 3 0 5-2 5-3 2-5 6-7 7-3s8 5 16 0c8-3 8-4 2-11l-8-14c-3-7-3-7-3-3l-2 12-3 8c0 2-9 6-10 4l1-11c1-8 2-11 0-12v-2c4 0 12-14 12-19-1-8 3-24 7-33 3-6 2-14-2-11-6 3-26-6-33-16-7-8-10-9-15-6-4 4-7-2-2-6 15-13 58-5 61 11l2 8v4l7-5c8-6 19-11 28-12l6-1-1-19c0-20 0-28 3-22l1 8 2 10c2 3 2 4 0 5l-2 10v9h4c8 0 21 4 29 10l7 4 1-5c1-7 6-13 11-14l6-2c2-2 23-1 34 2 6 1 8 2 11 7 6 8 3 10-5 5-8-6-9-6-14 2-7 9-20 15-31 15l-4 1c0 2 6 9 8 9 15 0 35-3 44-6 11-4 12-3 13 6 1 4 0 6-2 10-9 12-12 38-7 56l3 10-3 6c-3 8-12 22-20 31l-6 6h-9c-20 0-45 12-56 27-3 5-15 6-31 4m80-168c10-3 15-14 6-16-3 0-4 0-6 3-4 4-7 4-10 1-4-4-5-4-6 1-2 3-1 4 3 8 5 4 6 5 13 3m-122-5c4-4 5-5 4-8-1-4-5-5-8-2-4 3-6 3-9 1-2-2-2-3 2-4l-6-1c-11 0-12 2-7 9 7 8 17 10 24 5",
        ),
        attribute.attribute("fill", "#b6cdf3"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-23-5-32-14-33-34-1-32-25-47-54-36-19 6-35-3-46-27-14-29-12-37 10-50 14-7 19-19 19-39 0-16-1-19-14-31-16-16-17-22-4-42 17-27 29-32 48-21 13 8 27 8 43 1 17-9 22-15 26-36 3-15 10-19 31-19 34 0 44 7 46 29 1 18 1 20 7 26 15 18 34 25 53 18 20-8 31-1 43 28 10 24 9 39-4 46-31 16-37 50-13 69 18 14 18 32 0 56-14 18-19 20-36 11-30-16-70 1-75 32-2 13-3 16-8 19-6 3-26 3-39 0m28-15c4-2 7-6 9-18 7-32 45-49 77-33 16 8 21 7 32-6 15-19 16-28 2-42-25-27-21-66 8-84 15-8 17-17 9-36-9-18-15-22-33-17-34 9-68-14-71-48-1-18-4-21-24-25-22-4-30 0-35 18-8 35-45 52-77 36-17-9-22-8-33 6-14 20-15 29-2 42 25 25 21 63-8 84-16 11-17 17-9 33 10 20 17 24 35 20 34-7 68 17 68 49 1 11 3 16 9 19 10 6 35 7 43 2m-23-37c-17-3-26-7-32-15-7-8-20-17-31-22-16-7-17-14-3-20l9-5 4-5 3-3 1 4c2 7 14 4 26-6 6-6 6-7 0-14l-6-13-4-9c-1-3-9 10-9 15l-2 11-3 8c0 2-9 6-10 4l1-11c1-8 2-11 0-12v-2c3 0 15-17 19-27 6-14 4-40-2-36-6 3-26-6-33-16-7-8-10-9-15-6-3 2-4 2-4-2 0-9 35-14 50-7 12 6 13 8 16 34l1 8 6-7c7-7 17-13 27-14 5-1 7-2 7-3-1-5-2-49-1-52s3 1 3 9l2 10c2 3 2 4 0 5l-1 16v14l7 1c9 1 19 6 26 14l6 6v-10c0-17 4-25 13-27l5-2c2-2 21-1 33 2 7 1 8 2 12 7 6 8 3 10-5 5-8-6-9-6-14 2-7 8-19 14-31 15-4 0-6 3-6 8v3l19-1 31-4 11-3 1 3c3 7 3 12 0 18-6 12-8 36-4 50 4 16-23 55-37 55-16 0-37 9-48 20l-7 7-12 1zm84-166c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8m-125-3c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-8 9 7 8 16 10 24 5",
        ),
        attribute.attribute("fill", "#acc9f8"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-23-5-32-14-33-34-1-32-25-47-54-36-19 6-35-3-46-27-14-29-12-37 10-50 14-7 19-19 19-39 0-16-1-19-14-31-16-16-17-22-4-42 17-27 29-32 48-21 13 8 27 8 43 1 17-9 22-15 26-36 3-15 10-19 31-19 34 0 44 7 46 29 1 18 1 20 7 26 15 18 34 25 53 18 20-8 31-1 43 28 10 24 9 39-4 46-31 16-37 50-13 69 18 14 18 32 0 56-14 18-19 20-36 11-30-16-70 1-75 32-2 13-3 16-8 19-6 3-26 3-39 0m28-15c4-2 7-6 9-18 7-32 45-49 77-33 16 8 21 7 32-6 15-19 16-28 2-42-25-27-21-66 8-84 15-8 17-17 9-36-9-18-15-22-33-17-34 9-68-14-71-48-1-18-4-21-24-25-22-4-30 0-35 18-8 35-45 52-77 36-17-9-22-8-33 6-14 20-15 29-2 42 25 25 21 63-8 84-16 11-17 17-9 33 10 20 17 24 35 20 34-7 68 17 68 49 1 11 3 16 9 19 10 6 35 7 43 2m-17-44c-26-3-48-15-66-34-13-13-13-13-4-17l8-5c2-6 6-7 7-3 2 7 14 4 26-6 6-6 6-7 0-14l-6-13-4-9c-1-3-9 10-9 15l-2 11-3 8c0 2-9 6-10 4l1-11c1-8 2-11 0-12v-2c3 0 15-17 19-27 6-14 4-40-2-36-6 3-26-6-33-16-7-8-10-9-15-6-3 2-4 2-4-2 0-9 35-14 50-7 12 6 13 8 16 34l1 8 6-7c7-7 17-13 27-14 5-1 7-2 7-3-1-5-2-49-1-52s3 1 3 9l2 10c2 3 2 4 0 5l-1 16v14l7 1c9 1 19 6 26 14l6 6v-10c0-17 4-25 13-27l5-2c2-2 21-1 33 2 7 1 8 2 12 7 6 8 3 10-5 5-8-6-9-6-14 2-7 8-19 14-31 15-4 0-6 3-6 8v3l20-1 28-3c8-2 7-4 10 10 2 9 2 12 0 17l-2 22c-2 33-25 69-47 74-9 2-21 8-30 14-5 3-24 7-29 6zm78-159c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8m-125-3c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-8 9 7 8 16 10 24 5",
        ),
        attribute.attribute("fill", "#b3c9ed"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-23-5-32-14-33-34-1-32-25-47-54-36-19 6-35-3-46-27-14-29-12-37 10-50 14-7 19-19 19-39 0-16-1-19-14-31-16-16-17-22-4-42 17-27 29-32 48-21 13 8 27 8 43 1 17-9 22-15 26-36 3-15 10-19 31-19 34 0 44 7 46 29 1 18 1 20 7 26 15 18 34 25 53 18 20-8 31-1 43 28 10 24 9 39-4 46-31 16-37 50-13 69 18 14 18 32 0 56-14 18-19 20-36 11-30-16-70 1-75 32-2 13-3 16-8 19-6 3-26 3-39 0m28-15c4-2 7-6 9-18 7-32 45-49 77-33 16 8 21 7 32-6 15-19 16-28 2-42-25-27-21-66 8-84 15-8 17-17 9-36-9-18-15-22-33-17-34 9-68-14-71-48-1-18-4-21-24-25-22-4-30 0-35 18-8 35-45 52-77 36-17-9-22-8-33 6-14 20-15 29-2 42 25 25 21 63-8 84-16 11-17 17-9 33 10 20 17 24 35 20 34-7 68 17 68 49 1 11 3 16 9 19 10 6 35 7 43 2m-17-44c-26-3-48-15-66-34-13-13-13-13-4-17l7-4 3-4 3-4 2 4c5 12 32-4 31-18q0-10.5 3-6c4 7 8-4 4-11-16-29 16-63 44-45 7 4 7 4 22 1 3-1 3-1 3-12 0-18 3-26 13-28l5-2c2-2 21-1 33 2 7 1 8 2 12 7 6 8 3 10-5 5-8-6-9-6-14 1-7 9-19 15-31 16-4 0-6 3-6 8v3l20-1 28-3c8-2 7-4 10 10 2 9 2 12 0 17l-2 22c-2 33-25 69-47 74-9 2-21 8-30 14-5 3-24 7-29 6zm78-159c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M97 213c-1-1 0-6 1-12 1-7 2-10 0-11v-2c3 0 14-16 19-25 6-13 4-42-2-38-7 4-38-14-38-23 0-1-7-1-10 1s-4 2-4-2c0-9 35-13 51-6 11 6 12 8 14 33 3 27 2 31-11 51-4 5-5 8-5 11l-2 9-3 8c-1 5-9 9-10 6m16-99c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-8 9 7 8 16 10 24 5m57-1c-1-4-3-48-1-51 1-4 3 0 3 8l2 10c1 3 2 4 0 4-1 1-2 6-2 16 0 9-1 14-2 13",
        ),
        attribute.attribute("fill", "#a8c6f6"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-23-5-32-14-33-34-1-32-25-47-54-36-19 6-35-3-46-27-14-29-12-37 10-50 14-7 19-19 19-39 0-16-1-19-14-31-16-16-17-22-4-42 17-27 29-32 48-21 13 8 27 8 43 1 17-9 22-15 26-36 3-15 10-19 31-19 34 0 44 7 46 29 1 18 1 20 7 26 15 18 34 25 53 18 20-8 31-1 43 28 10 24 9 39-4 46-31 16-37 50-13 69 18 14 18 32 0 56-14 18-19 20-36 11-30-16-70 1-75 32-2 13-3 16-8 19-6 3-26 3-39 0m28-15c4-2 7-6 9-18 7-32 45-49 77-33 16 8 21 7 32-6 15-19 16-28 2-42-25-27-21-66 8-84 15-8 17-17 9-36-9-18-15-22-33-17-34 9-68-14-71-48-1-18-4-21-24-25-22-4-30 0-35 18-8 35-45 52-77 36-17-9-22-8-33 6-14 20-15 29-2 42 25 25 21 63-8 84-16 11-17 17-9 33 10 20 17 24 35 20 34-7 68 17 68 49 1 11 3 16 9 19 10 6 35 7 43 2m-26-53c-9-2-28-9-29-11h-4c-3 0-4 0-3-2v-2c-2 0-19-17-23-22l-3-4 4-2 4-3 3-4 3-4 2 4c5 12 32-4 31-18q0-10.5 3-6c4 7 8-4 4-11-16-29 16-63 44-45 7 4 7 4 22 1 3-1 3-1 3-12 0-18 3-26 13-28l5-2c2-2 21-1 33 2 7 1 8 2 12 7 6 8 3 10-5 5-8-6-9-6-14 1-7 9-19 15-31 16-4 0-6 3-6 8v3l20-1 24-1c6-1 8 7 8 29 0 66-57 115-120 102m87-150c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M97 213c-1-1 0-6 1-12 1-7 2-10 0-11v-2c3 0 14-16 19-25 6-13 4-42-2-38-7 4-38-14-38-23 0-1-7-1-10 1s-4 2-4-2c0-9 35-13 51-6 11 6 12 8 14 33 3 27 2 31-11 51-4 5-5 8-5 11l-2 9-3 8c-1 5-9 9-10 6m16-99c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-8 9 7 8 16 10 24 5m57-1c-1-4-3-48-1-51 1-4 3 0 3 8l2 10c1 3 2 4 0 4-1 1-2 6-2 16 0 9-1 14-2 13",
        ),
        attribute.attribute("fill", "#acc4ea"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-23-5-32-14-33-34-1-32-25-47-54-36-19 6-35-3-46-27-14-29-12-37 10-50 14-7 19-19 19-39 0-16-1-19-14-31-16-16-17-22-4-42 17-27 29-32 48-21 13 8 27 8 43 1 17-9 22-15 26-36 3-15 10-19 31-19 34 0 44 7 46 29 1 18 1 20 7 26 15 18 34 25 53 18 20-8 31-1 43 28 10 24 9 39-4 46-31 16-37 50-13 69 18 14 18 32 0 56-14 18-19 20-36 11-30-16-70 1-75 32-2 13-3 16-8 19-6 3-26 3-39 0m28-15c4-2 7-6 9-18 7-32 45-49 77-33 16 8 21 7 32-6 15-19 16-28 2-42-25-27-21-66 8-84 15-8 17-17 9-36-9-18-15-22-33-17-34 9-68-14-71-48-1-18-4-21-24-25-22-4-30 0-35 18-8 35-45 52-77 36-17-9-22-8-33 6-14 20-15 29-2 42 25 25 21 63-8 84-16 11-17 17-9 33 10 20 17 24 35 20 34-7 68 17 68 49 1 11 3 16 9 19 10 6 35 7 43 2m-26-53c-9-2-28-9-29-11h-4c-3 0-4 0-3-2v-2c-2 0-19-17-23-22l-3-4 4-2c2-1 5-3 6-6 3-4 4-4 6 0 5 11 32-6 31-19 0-7 1-8 4-5 2 2 5-1 12-16 13-24 34-39 56-39h4v-11c0-19 4-29 11-29l6-2c4-3 20-2 34 1 7 1 8 2 12 7 6 8 3 10-5 5-8-6-9-6-14 1-7 9-20 16-31 16-4 0-6 3-6 8 0 3 16 3 44 1 6-1 8 7 8 29 0 66-57 115-120 102m87-150c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M97 213c-1-1 0-6 1-12s2-10 1-11-1-2 1-3c19-6 28-61 11-63-14-1-30-11-33-20-1-3-7-3-11-1-3 2-4 2-4-2 0-9 35-13 51-6 14 7 23 55 12 68l-2 3-5 9c-6 9-9 17-7 17l-2 6-3 9c-1 5-9 9-10 6m16-99c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-8 9 7 8 16 10 24 5m57-2c-1-5-3-47-1-50 1-4 3 0 3 8l2 10c1 3 2 4 0 4-1 1-2 6-2 16s-1 14-2 12",
        ),
        attribute.attribute("fill", "#a3c2f4"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-23-5-32-14-33-34-1-32-25-47-54-36-19 6-35-3-46-27-14-29-12-37 10-50 14-7 19-19 19-39 0-16-1-19-14-31-16-16-17-22-4-42 17-27 29-32 48-21 13 8 27 8 43 1 17-9 22-15 26-36 3-15 10-19 31-19 34 0 44 7 46 29 1 18 1 20 7 26 15 18 34 25 53 18 20-8 31-1 43 28 10 24 9 39-4 46-31 16-37 50-13 69 18 14 18 32 0 56-14 18-19 20-36 11-30-16-70 1-75 32-2 13-3 16-8 19-6 3-26 3-39 0m28-15c4-2 7-6 9-18 7-32 45-49 77-33 16 8 21 7 32-6 15-19 16-28 2-42-25-27-21-66 8-84 15-8 17-17 9-36-9-18-15-22-33-17-34 9-68-14-71-48-1-18-4-21-24-25-22-4-30 0-35 18-8 35-45 52-77 36-17-9-22-8-33 6-14 20-15 29-2 42 25 25 21 63-8 84-16 11-17 17-9 33 10 20 17 24 35 20 34-7 68 17 68 49 1 11 3 16 9 19 10 6 35 7 43 2m-21-60c-10-2-18-5-28-10-9-5-10-5-12 1-1 1-3 0-5-2-1-2-3-4-2-5h-3c-2 0-2 0-2-3 1-2 1-2-1-1-2 2-2 2-1 0l-1-2c-1 1-2-1-3-4l-2-5-2-4v-1c1 1 2 0 4-3 3-7 5-7 7-3 5 11 32-6 31-19 0-7 1-8 4-5 2 2 5-1 12-16 13-24 34-39 56-39h4v-11c0-19 4-29 11-29l6-2c4-3 20-2 34 1 7 1 8 2 12 7 6 8 3 10-5 5-8-6-9-6-14 1-7 9-20 16-31 16-4 0-6 3-6 8 0 3 0 3 20 2h21l1 6c6 26 1 55-13 76l-5 9c0 5-3 11-6 11-2 0-3 0-1 1 2 2 2 4 0 3l-1 1-3 1c-2-1-3 0-3 2s-1 3-2 3l-2-2c0-2-5-1-14 4-15 8-39 11-55 8m82-143c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M115 255l2-3c1 0 2 0 1 1l-2 3zm-18-42c-1-1 0-6 1-12s2-10 1-11-1-2 1-3c19-6 28-61 11-63-14-1-30-11-33-20-1-3-7-3-11-1-3 2-4 2-4-2 0-9 35-13 51-6 14 7 23 55 12 68l-2 3-5 9c-6 9-9 17-7 17l-2 6-3 9c-1 5-9 9-10 6m16-99c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-8 9 7 8 16 10 24 5m57-2c-1-5-3-47-1-50 1-4 3 0 3 8l2 10c1 3 2 4 0 4-1 1-2 6-2 16s-1 14-2 12",
        ),
        attribute.attribute("fill", "#b8c4d3"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-24-5-32-14-33-33 0-32-24-48-55-37-11 4-14 4-19 0l-5-2c-8 0-23-25-28-43-4-15-1-21 16-30 15-9 20-20 20-42 0-15-1-18-14-30-16-15-17-22-4-41 18-29 29-34 48-22 27 16 62 0 68-31 4-19 9-23 30-23 37 0 46 7 48 33 1 17 4 23 17 32 17 12 26 14 43 8 21-7 30-2 42 27 11 25 10 40-3 47-30 16-37 50-14 69 19 15 19 33 0 57-14 17-19 19-36 9-16-8-26-9-44 0-20 9-26 16-31 35-4 19-17 24-46 17m27-15c5-2 7-6 10-18 5-22 25-37 51-39 10-1 10 0 32 9 25 11 48-30 28-51-25-27-21-66 8-83 16-10 17-18 8-38-8-18-14-21-33-16-33 9-66-14-69-47-2-20-6-24-29-27-19-2-26 1-30 17-6 20-12 28-29 37-20 10-31 10-49 1-17-9-21-8-32 5-16 19-16 29-3 43 25 26 21 64-9 85-26 18-5 60 27 52 33-8 66 15 68 48 1 14 3 17 10 21 10 5 33 6 41 1m-20-60c-10-2-18-5-28-10-9-5-10-5-12 1-1 1-3 0-5-2-1-2-3-4-2-5h-3c-2 0-2 0-2-3 1-2 1-2-1-1-2 2-2 2-1 0l-1-2c-1 1-2-1-3-4l-2-5-2-4v-1c1 1 2 0 4-3 3-7 5-7 7-3 5 11 32-6 31-19 0-7 1-8 4-5 2 2 5-1 12-16 13-24 34-39 56-39h4v-11c0-27 8-34 33-33 21 2 25 3 30 11 6 7 3 9-5 4-7-6-9-6-13 0-8 11-21 17-32 17-4 0-6 3-6 8 0 3 0 3 20 2h21l1 6c6 26 1 55-13 76l-5 9c0 5-3 11-6 11-2 0-3 0-1 1 2 2 2 4 0 3l-1 1-3 1c-2-1-3 0-3 2s-1 3-2 3l-2-2c0-2-5-1-14 4-15 8-39 11-55 8m82-143c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M115 255l2-3c1 0 2 0 1 1l-2 3zm-19-43 2-11c1-5 2-10 1-11 0 0 0-2 2-3 22-23 28-61 10-63-13-1-34-14-34-22l-11 1c-3 1-3 1-3-1 0-15 53-14 61 1 6 10 7 54 2 60l-2 3-5 9c-6 9-9 17-7 17l-2 7-3 9-3 4c-3 2-8 2-8 0m17-98c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-7 9 7 9 15 10 23 5m57-2c-1-5-3-47-1-50 1-4 3 1 3 8l2 10c1 3 2 4 0 4-1 1-2 6-2 16s-1 14-2 12",
        ),
        attribute.attribute("fill", "#a0bef0"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-24-5-32-14-33-33 0-32-24-48-55-37-11 4-14 4-19 0l-5-2c-8 0-23-25-28-43-4-15-1-21 16-30 15-9 20-20 20-42 0-15-1-18-14-30-16-15-17-22-4-41 18-29 29-34 48-22 27 16 62 0 68-31 4-19 9-23 30-23 37 0 46 7 48 33 1 17 4 23 17 32 17 12 26 14 43 8 21-7 30-2 42 27 11 25 10 40-3 47-30 16-37 50-14 69 19 15 19 33 0 57-14 17-19 19-36 9-16-8-26-9-44 0-20 9-26 16-31 35-4 19-17 24-46 17m27-15c5-2 7-6 10-18 5-22 25-37 51-39 10-1 10 0 32 9 25 11 48-30 28-51-25-27-21-66 8-83 16-10 17-18 8-38-8-18-14-21-33-16-33 9-66-14-69-47-2-20-6-24-29-27-19-2-26 1-30 17-6 20-12 28-29 37-20 10-31 10-49 1-17-9-21-8-32 5-16 19-16 29-3 43 25 26 21 64-9 85-26 18-5 60 27 52 33-8 66 15 68 48 1 14 3 17 10 21 10 5 33 6 41 1m-27-65-19-8-10-5-2 5c-2 5-6 6-5 2l-1-2c-3 0-4-1-3-2 0-2 0-2-2-1-3 0-3 0-3-2 1-2 1-3-1-2-1 0-2 0-1-1l-1-1c-1 1-2-1-3-4l-2-5-2-4v-1c1 1 2 0 4-3 3-7 5-7 7-3 5 11 32-5 31-18 0-8 1-9 4-6 2 2 5-1 10-12 13-26 29-39 53-42l9-2v-10c0-27 8-34 33-33 21 2 25 3 30 11 6 7 3 9-5 4-7-6-9-6-13 0-8 11-21 17-32 17-4 0-6 3-6 8 0 2 0 3 18 2h19l2 9c5 22 0 49-11 68-3 4-5 9-5 11 1 6-2 14-5 14-2 0-3 0-1 1 2 2 2 4 0 3l-1 1-3 1c-2-1-3 0-3 2s0 3-3 2l-1-1-2-1c-3 0-2-4 1-6l4-1 1-1c2-2-4 0-8 3a89 89 0 0 1-72 13m89-138c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M115 255l2-3c1 0 2 0 1 1l-2 3zm-19-43 2-11c1-5 2-10 1-11 0 0 0-2 2-3 22-23 28-61 10-63-13-1-34-14-34-22l-11 1c-3 1-3 1-3-1 0-15 53-14 61 1 6 10 7 54 2 60l-2 3-5 9c-6 9-9 17-7 17l-2 7-3 9-3 4c-3 2-8 2-8 0m17-98c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-7 9 7 9 15 10 23 5m57-2c-1-5-3-47-1-50 1-4 3 1 3 8l2 10c1 3 2 4 0 4-1 1-2 6-2 16s-1 14-2 12",
        ),
        attribute.attribute("fill", "#9dbdf0"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-24-5-32-14-33-33 0-32-24-48-55-37-11 4-14 4-19 0l-5-2c-8 0-23-25-28-43-4-15-1-21 16-30 15-9 20-20 20-42 0-15-1-18-14-30-16-15-17-22-4-41 18-29 29-34 48-22 27 16 62 0 68-31 4-19 9-23 30-23 37 0 46 7 48 33 1 17 4 23 17 32 17 12 26 14 43 8 21-7 30-2 42 27 11 25 10 40-3 47-30 16-37 50-14 69 19 15 19 33 0 57-14 17-19 19-36 9-16-8-26-9-44 0-20 9-26 16-31 35-4 19-17 24-46 17m27-15c5-2 7-6 10-18 5-22 25-37 51-39 10-1 10 0 32 9 25 11 48-30 28-51-25-27-21-66 8-83 16-10 17-18 8-38-8-18-14-21-33-16-33 9-66-14-69-47-2-20-6-24-29-27-19-2-26 1-30 17-6 20-12 28-29 37-20 10-31 10-49 1-17-9-21-8-32 5-16 19-16 29-3 43 25 26 21 64-9 85-26 18-5 60 27 52 33-8 66 15 68 48 1 14 3 17 10 21 10 5 33 6 41 1m-61-65 2-3c1 0 2 0 1 1l-2 3zm-2-4v-3l-1-1c-2 0-4-1-3-2 0-2 0-2-2-1-3 0-3 0-3-2 1-2 1-3-1-2-1 0-2 0-1-1l-1-1c-1 1-2-1-3-4l-2-5-2-4v-1c1 1 2 0 4-3 3-7 5-7 7-3 5 11 32-5 31-18 0-8 1-9 4-6 2 2 5-1 10-12 13-26 29-39 53-42l9-2v-10c0-27 8-34 33-33 21 2 25 3 30 11 6 7 3 9-5 4-7-6-9-6-13 0-8 11-21 17-32 17-4 0-6 3-6 8 0 2 1 2 15 3h16l2 7c5 17 2 43-7 60l-4 11c4 5 0 23-4 23-2 0-3 0-1 1 2 3 2 5-1 3-1-2-2-2-1 0s1 2-2 2c-2-1-3-1-3 2 0 2-1 3-3 2l-1-1-2-1c-2 0-2-4 1-5l5-2-3-3-3-4-8 6a84 84 0 0 1-86 0c-7-4-10-4-11-1 0 1 0 2 1 1 2 0 2 1-1 6-2 7-4 8-5 6m3-22c-3-2-5-3-6-2s-1 1 5 4 6 3 1-2m124 2-2-1c0-1-1 0 0 0 1 2 2 3 2 1m-2-114c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M96 212l2-11c1-5 2-10 1-11 0 0 0-2 2-3 22-23 28-61 10-63-13-1-34-14-34-22l-11 1c-3 1-3 1-3-1 0-15 53-14 61 1 6 10 7 54 2 60l-2 3-5 9c-6 9-9 17-7 17l-2 7-3 9-3 4c-3 2-8 2-8 0m17-98c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-7 9 7 9 15 10 23 5m57-2c-1-5-3-47-1-50 1-4 3 1 3 8l2 10c1 3 2 4 0 4-1 1-2 6-2 16s-1 14-2 12",
        ),
        attribute.attribute("fill", "#99baee"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-24-5-32-14-33-33 0-32-24-48-55-37-11 4-14 4-19 0l-5-2c-8 0-23-25-28-43-4-15-1-21 16-30 15-9 20-20 20-42 0-15-1-18-14-30-16-15-17-22-4-41 18-29 29-34 48-22 27 16 62 0 68-31 4-19 9-23 30-23 37 0 46 7 48 33 1 17 4 23 17 32 17 12 26 14 43 8 21-7 30-2 42 27 11 25 10 40-3 47-30 16-37 50-14 69 19 15 19 33 0 57-14 17-19 19-36 9-16-8-26-9-44 0-20 9-26 16-31 35-4 19-17 24-46 17m27-15c5-2 7-6 10-18 5-22 25-37 51-39 10-1 10 0 32 9 25 11 48-30 28-51-25-27-21-66 8-83 16-10 17-18 8-38-8-18-14-21-33-16-33 9-66-14-69-47-2-20-6-24-29-27-19-2-26 1-30 17-6 20-12 28-29 37-20 10-31 10-49 1-17-9-21-8-32 5-16 19-16 29-3 43 25 26 21 64-9 85-26 18-5 60 27 52 33-8 66 15 68 48 1 14 3 17 10 21 10 5 33 6 41 1m-61-66c1-1 0-2-1-3-1 0-2-1-1-2l-1-2c-1 1-1 1-1-1 1-2 1-2-1-1-2 2-2 2-1 0 0-2 0-2-2-1-3 0-3 0-3-2 1-2 1-3-1-2-2 0-2 0 0-3 1-3 1-3-1 0-3 2-3 2-3 0l-3-8-2-5c1 1 2 0 3-3 2-5 6-8 7-5l4 5c3 3 3 4 2 6l-1 3c3-2 13 4 10 6-2 2-3 5 0 3 2-1 1 2-1 7-2 4-2 5-1 6s2 2 1 3c-1 2-3 1-3-1m110-5c-1-1-1-1 0 0 1 0 1-1-1-2-3-3-1-7 5-7l-3-3c-4-5-4-6 1-7 4-2 7-8 7-16 1-6 0-6-6 1-23 32-73 36-104 10l-6-5 5-3c12-7 14-9 13-18 0-7 1-9 4-5 2 2 5-2 12-15 12-23 28-35 50-39l10-2v-10c0-27 8-34 33-33 21 2 25 3 30 11 6 7 3 9-5 4-7-6-9-6-13 0-8 11-21 17-32 17-4 0-6 3-6 8 0 3 0 3 11 3l11-1 2 5c3 9 3 33 0 43-2 8-3 22-1 38 1 8 1 8-2 7-3 0-3 0-1 2 3 3 2 7-2 7-2 0-2 0-1 2 2 2 2 2 0 1-2 0-2 0-2 2 1 1 0 1-2 1-2-1-3-1-3 1 0 3-3 5-4 3m13-132c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M96 212l2-11c1-5 2-10 1-11 0 0 0-2 2-3 22-23 28-61 10-63-13-1-34-14-34-22l-11 1c-3 1-3 1-3-1 0-15 53-14 61 1 6 10 7 54 2 60l-2 3-5 9c-6 9-9 17-7 17l-2 7-3 9-3 4c-3 2-8 2-8 0m17-98c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-7 9 7 9 15 10 23 5m57-2c-1-5-3-47-1-50 1-4 3 1 3 8l2 10c1 3 2 4 0 4-1 1-2 6-2 16s-1 14-2 12",
        ),
        attribute.attribute("fill", "#92b5eb"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-24-5-32-14-33-33 0-32-24-48-55-37-11 4-14 4-19 0l-5-2c-8 0-23-25-28-43-4-15-1-21 16-30 15-9 20-20 20-42 0-15-1-18-14-30-16-15-17-22-4-41 18-29 29-34 48-22 27 16 62 0 68-31 4-19 9-23 30-23 37 0 46 7 48 33 1 17 4 23 17 32 17 12 26 14 43 8 21-7 30-2 42 27 11 25 10 40-3 47-30 16-37 50-14 69 19 15 19 33 0 57-14 17-19 19-36 9-16-8-26-9-44 0-20 9-26 16-31 35-4 19-17 24-46 17m27-15c5-2 7-6 10-18 5-22 25-37 51-39 10-1 10 0 32 9 25 11 48-30 28-51-25-27-21-66 8-83 16-10 17-18 8-38-8-18-14-21-33-16-33 9-66-14-69-47-2-20-6-24-29-27-19-2-26 1-30 17-6 20-12 28-29 37-20 10-31 10-49 1-17-9-21-8-32 5-16 19-16 29-3 43 25 26 21 64-9 85-26 18-5 60 27 52 33-8 66 15 68 48 1 14 3 17 10 21 10 5 33 6 41 1m-61-66c1-1 0-2-1-3-1 0-2-1-1-2l-1-2c-1 1-2 1-1-1v-1l-2-1h-3c-2 0-2 0-2-2 1-2 1-3-1-2-2 0-2 0 0-3 1-3 1-3-1 0-3 2-4 2-3-4l-3-5-3-5 1 1c1 1 2 0 3-3 2-5 6-8 7-5l4 5c2 2 3 3 1 5v4c1-1 9 2 11 4l-1 3c-2 1-2 2-1 3 2 1 2 2 0 6s-2 5-1 6 2 2 1 3c-1 2-3 1-3-1m110-5c-1-1-1-1 0 0 1 0 1-1-1-2-3-3-1-7 5-7l-3-3c-4-5-4-6 1-7 6-1 9-14 6-25l-2-8c0-2-2-1-4 4-8 14-28 28-43 30l-5 3-3 1c-2 0-2 0 0 1s2 1 0 3-2 2-3 0l-2-1q0 3-3 0c-2-1-2-2-2-3q1.5-3-6-3c-8-1-22-7-28-13l-4-3 4-5c4-4 5-5 4-12 0-7 1-8 4-5 2 2 6-3 13-15 11-24 28-36 52-40l7-1v-10c0-27 8-34 33-33 21 2 25 3 30 11 6 7 3 9-5 4-7-6-9-6-13 0-8 11-21 17-32 17-9-1-9 11 0 12h6l3 8 2 21c0 13 0 19 3 25l2 12 1 18c1 8 1 8-2 7-3 0-3 0-1 2 3 3 2 7-2 7-2 0-2 0-1 2 2 2 2 2 0 1-2 0-3 0-2 1l-2 1c-2 0-3 1-3 2 0 3-3 5-4 3m13-132c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M96 212l2-11c1-5 2-10 1-11 0 0 0-2 2-3 22-23 28-61 10-63-13-1-34-14-34-22l-11 1c-3 1-3 1-3-1 0-15 53-14 61 1 6 10 7 54 2 60l-2 3-5 9c-6 9-9 17-7 17l-2 7-3 9-3 4c-3 2-8 2-8 0m17-98c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-7 9 7 9 15 10 23 5m57-2c-1-5-3-47-1-50 1-4 3 1 3 8l2 10c1 3 2 4 0 4-1 1-2 6-2 16s-1 14-2 12",
        ),
        attribute.attribute("fill", "#a8b7ca"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-23-5-32-14-32-33-1-32-25-48-56-37-11 4-14 4-18 1l-9-5c-13-7-29-39-26-55 1-6 5-10 17-16 26-15 29-52 5-73-15-13-15-21-4-40 18-28 30-33 49-22 27 16 63-1 68-31 4-19 9-23 32-23 35 0 44 7 46 33 2 31 30 50 60 40 20-7 28-2 40 21 14 29 13 45-2 53-29 16-36 49-13 68 19 16 19 34 0 58-14 17-19 19-35 10-17-9-27-10-45-1-20 9-26 16-31 35-4 19-17 24-46 17m27-14c5-3 7-7 10-17 8-34 43-50 77-35 18 9 24 7 36-11 12-19 11-23-2-37-25-27-21-67 8-83 16-9 18-18 8-38-8-18-14-21-33-16-33 9-66-14-69-48-2-18-6-22-27-26-20-3-27 1-32 17-6 20-11 28-28 36-19 10-34 11-51 1-15-8-21-7-31 6-16 19-16 29-3 43 24 26 21 64-9 84-14 10-16 16-9 31 10 22 18 26 37 22 32-8 64 16 67 48 1 14 3 19 11 22 10 4 32 5 40 1m-61-67c1-1 0-2-1-3-1 0-2-1-1-2l-1-2c-1 1-2 1-1-1v-1l-2-1h-3c-2 0-2 0-2-2 1-2 1-3-1-2-2 0-2 0 0-3 1-3 1-3-1 0-3 2-3 2-3-1l-4-8c-1-2-2-4-1-5l1 1 3-4c4-5 6-7 6-4l3 5c3 2 4 3 2 5v4c1-1 9 2 11 4l-1 3c-2 1-2 2-1 3 2 1 2 2 0 6s-2 5-1 6 2 2 1 3c-1 2-3 1-3-1m110-5c-1-1-1-1 0 0 1 0 1-1-1-2-3-3-1-7 5-7l-3-3c-4-5-4-6 1-7 6-1 9-14 6-25l-2-8c0-2-2-1-4 4-8 14-28 28-43 30l-5 3-3 1c-2 0-2 0 0 1s2 1 0 3-2 2-3 0l-2-1q0 3-3 0c-2-1-2-2-2-3q1.5-3-6-3c-8-1-22-7-28-13l-4-3 4-5c5-5 5-5 4-12 0-7 1-9 4-6 2 3 5 0 12-13 13-25 29-37 53-41l7-1v-14c1-15 3-22 8-24 10-5 17-6 32-4 16 2 19 3 23 10 5 7 3 9-5 3-8-5-8-5-16 4-6 7-9 9-15 10l-10 3-5 1c-4-1-5 2-5 7 0 4 0 5 6 5h6l3 8 2 21c0 13 0 19 3 25l2 12 1 18c1 8 1 8-2 7-3 0-3 0-1 2 3 3 2 7-2 7-2 0-2 0-1 2 2 2 2 2 0 1-2 0-3 0-2 1l-2 1c-2 0-3 1-3 2 0 3-3 5-4 3m13-132c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M96 212l2-10c1-5 2-10 1-12l1-3c15-9 29-61 18-62-21-2-29-6-41-22-2-3-3-3-7-1-8 3-10 1-5-4 20-20 59-5 63 24 3 29 1 39-12 57-2 4-4 8-4 12l-3 10-2 6c0 3-4 6-8 6zm17-98c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-7 9 7 9 15 10 23 5m57-3c-2-8-1-54 1-49l1 8 2 10c1 3 2 4 0 4-1 1-2 6-2 15s-1 14-2 12",
        ),
        attribute.attribute("fill", "#8db1e8"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M149 335c-23-5-32-14-32-33-1-32-25-48-56-37-11 4-14 4-18 1l-9-5c-13-7-29-39-26-55 1-6 5-10 17-16 26-15 29-52 5-73-15-13-15-21-4-40 18-28 30-33 49-22 27 16 63-1 68-31 4-19 9-23 32-23 35 0 44 7 46 33 2 31 30 50 60 40 20-7 28-2 40 21 14 29 13 45-2 53-29 16-36 49-13 68 19 16 19 34 0 58-14 17-19 19-35 10-17-9-27-10-45-1-20 9-26 16-31 35-4 19-17 24-46 17m27-14c5-3 7-7 10-17 8-34 43-50 77-35 18 9 24 7 36-11 12-19 11-23-2-37-25-27-21-67 8-83 16-9 18-18 8-38-8-18-14-21-33-16-33 9-66-14-69-48-2-18-6-22-27-26-20-3-27 1-32 17-6 20-11 28-28 36-19 10-34 11-51 1-15-8-21-7-31 6-16 19-16 29-3 43 24 26 21 64-9 84-14 10-16 16-9 31 10 22 18 26 37 22 32-8 64 16 67 48 1 14 3 19 11 22 10 4 32 5 40 1m-61-67c1-1 0-2-1-3-1 0-2-1-1-2l-1-2c-1 1-2 0-2-2-1-1-2-2-4-1-2 0-2 0-2-2 1-2 1-3-1-2-2 0-2 0 0-3 1-3 1-3-1 0-3 2-3 2-3-1l-4-8c-1-2-2-4-1-5l1 1 3-4c4-5 6-7 6-4l3 5c3 2 4 3 2 5v4c1-1 9 2 11 4l-1 3c-2 1-2 2-1 3 2 1 2 2 0 6s-2 5-1 6 2 2 1 3c-1 2-3 1-3-1m-2-10v-1l-2 1v1zm4-1v-2l-2 2v1zm108 6c-1-1-1-1 0 0 1 0 1-1-1-2-3-2-1-6 3-6l2-1-3-3c-4-5-4-6 1-7 6-2 11-22 5-28l-1-5c0-12-6-20-8-12-4 12-16 26-29 33-6 3-17 14-16 15 0 1 0 2-2 2s-2 0 0 1 2 1 0 3-2 2-3-1-1-3-2 0l-2 1-2-2c-1 0-2 0-1-2 1-3-1-8-4-8l-7-5-13-9c-4-2-7-5-6-5v-9c0-7 1-9 4-6 2 3 6 0 12-13 12-24 27-35 49-40l11-2v-14c1-15 3-22 8-24 10-5 17-6 32-4 16 2 19 3 23 10 5 7 3 9-5 3-8-5-8-5-16 4-6 7-9 9-15 10l-10 3-5 1c-6-1-7 6-3 15 2 3 4 10 5 16 1 7 3 14 6 20l5 11 2 4 2 12 1 18c1 8 1 8-2 7-3 0-3 0-1 2 3 3 2 7-3 6-3 0-3 0 0 2 2 3 2 3 0 2l-3 1c0 1 0 2-2 1l-2 2c0 3-3 5-4 3m13-132c10-5 11-14 1-14-1 0-4 1-5 3-3 4-6 4-9 1-3-4-5-4-6-1 0 2-1 3-2 3-6 5 13 12 21 8M96 212l2-10c1-5 2-10 1-12l1-3c15-9 29-61 18-62-21-2-29-6-41-22-2-3-3-3-7-1-8 3-10 1-5-4 20-20 59-5 63 24 3 29 1 39-12 57-2 4-4 8-4 12l-3 10-2 6c0 3-4 6-8 6zm17-98c5-3 6-4 5-7-2-6-7-8-10-3-2 3-5 3-8 1-2-3-2-4 3-3l4-1-10-1c-12 0-13 2-7 9 7 9 15 10 23 5m57-3c-2-8-1-54 1-49l1 8 2 10c1 3 2 4 0 4-1 1-2 6-2 15s-1 14-2 12",
        ),
        attribute.attribute("fill", "#87abe5"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M146 332c-21-3-29-10-29-28 0-33-30-55-61-44-37 12-66-50-33-69 28-16 33-54 8-74-17-14-17-24 3-50 14-18 24-22 40-12 29 16 64 1 70-31 3-21 14-26 47-21 23 3 28 8 29 30 2 32 30 51 61 42 21-7 27-4 39 20 14 28 12 37-6 48a45 45 0 0 0-9 73c17 15 17 25 1 47-17 23-25 26-43 16-30-16-64-1-70 32-3 20-14 25-47 21m26-9c8-3 12-7 14-19 8-34 45-50 77-34 17 9 27 4 40-18 8-13 7-19-7-34-23-25-19-61 7-79 17-11 20-17 13-34-8-21-16-26-32-23-21 6-29 5-44-4-21-12-28-23-29-43-2-19-8-24-32-25-19-1-24 2-28 19-9 34-47 52-77 35-18-10-29-5-41 20-7 13-6 18 6 31 24 24 20 62-8 81-16 11-18 17-11 32 11 22 19 27 41 22 29-7 62 18 64 48 1 22 21 32 47 25m-56-68c0-1 0-2 1-1v2zm-3-7v-5c1-1 2 0 1 2l2-2 4-4-2 6c-3 6-4 7-5 3m114-1-3-1-2-1v-1l3-1c3-3 4-3 6-2l2 3-3-1c-2-2-2-2-1 2 0 5 0 5-2 2m-118-2 2-4c1-3 1-3-2 0l-4 4 1-4c0-3 0-3-2-3-2 1 0-3 3-6 4-3 13 1 11 4l-2 3-1 2-4 2zm121-6q-9-6-3-9l4-2 5 2c5 3 5 8 0 8-3-1-3-1-1 1 3 4 1 4-5 0m-62-2-1-3c1-3-1-7-5-8-2 0-5-3-7-6-6-7-6-6-12-11-4-3-5-5-6-8-1-6 0-8 2-6 2 1 3 0 7-3 5-4 6-4 12-3 9 3 16 3 26 2 9-2 11-2 13-1 9 6 8 5 10 3 1-1 1-1 1 2 0 6-3 13-8 15-5 4-23 20-23 22l-2 1-2 2 3 1v2c-1 1-2 1-3-1zm-68 0-1-5-1-3c-4 0-1-9 4-13h2c-1 0 0 3 2 4l3 6c-1 4-8 12-9 11m136-9-4-2 2-6c2-6 1-15-2-19l-2-8c0-4-3-12-8-22l-8-15v-49l4-4 6-4 7-2c9-5 39 1 44 9 4 7 2 8-6 2-7-5-8-4-14 3-7 9-23 17-31 15-4-1-7 7-6 18 1 8 2 13 21 50l1 3v18c5 9 3 17-4 13m2-109c11-6 12-16 1-16-3 0-4 0-5 2-1 4-5 5-8 2-4-4-6-3-9 1-3 7 12 15 21 11M97 210l2-12c1-5 2-8 1-9v-1c2 0 12-15 17-25 8-18 6-39-4-39-12 0-23-6-31-16-7-9-8-9-14-6-5 3-6 2-4-2 4-8 36-11 48-5s13 8 15 30c3 28 3 31-11 54-4 5-5 10-5 12 0 6-6 20-9 21-4 2-5 2-5-2m17-96c6-4 6-7 1-11l-3-4-3 4c-4 4-5 4-7 2-3-3-2-4 2-3h4c0-2-10-4-16-3-10 1-6 11 6 16 7 4 10 4 16-1m56-8-1-26 1-21 1 10 2 12v3l-1 14c-1 9-1 11-2 7z",
        ),
        attribute.attribute("fill", "#536d88"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M146 332c-21-3-29-10-29-30 0-32-30-52-61-42-19 6-27 2-38-18-15-29-14-41 5-51 29-15 33-54 8-75-17-13-16-23 2-48 15-20 24-23 42-13 28 17 62 1 69-31 4-20 10-24 37-22 31 2 38 7 39 31 2 32 31 52 61 42 20-7 28-3 39 20 14 28 12 37-7 48a45 45 0 0 0-8 73c17 15 17 26 1 47-17 23-24 26-43 16-30-16-64-1-70 32-3 20-14 25-47 21m30-11c6-3 8-5 11-21 7-29 44-45 74-31 33 16 62-23 36-50-22-23-20-62 4-78l11-7c12-8 7-39-10-50l-6-4-12 2c-23 6-33 4-51-9-16-12-22-22-22-39 0-30-52-36-60-8-9 37-46 55-77 38-17-9-24-7-36 10-13 20-13 26 1 40 24 25 20 63-10 83-15 11-16 18-7 34 11 20 17 24 36 19 32-7 64 16 67 49 1 14 3 18 11 21 10 5 31 5 40 1m-60-66c0-1 0-2 1-1v2zm-3-6 4-6 3-4-2 6c-2 5-5 8-5 4m113-3c-1-1-2-3-1-4 1-2 3-1 3 3 1 5 1 5-2 1m-113-2 1-1v1l-1 1zm-7-3c0-3 0-4-2-3s0-3 3-6c4-3 13 1 10 5l-2 3v1l-3 1c-2 1-2 1-1-1 1-3 1-2-2 0l-4 4zm124 2 1-2 2 2-1 1zm-1-5c-6-4-6-6-1-8s5-2 9 0c4 3 4 8-1 8-3-1-3-1-1 1 2 3-1 3-6-1m-61-1-1-3c2-2-1-6-5-8-3-1-6-4-8-7l-10-9c-4-3-6-5-7-9-1-6 0-9 2-6 2 1 3 0 7-3l5-4 8 2c9 2 13 2 27 0 9-1 10-1 14 2s6 3 7 1l1 2c0 6-3 12-7 15a127 127 0 0 0-26 23l-2 2 3 1c1 0 2 0 0 2-1 1-2 1-4-1-2-3-3-3-2-1 1 3 0 3-2 1m-68 0-1-5-1-3c-4 0-1-9 4-13h2c-1 0 0 3 2 4l3 6c-1 4-8 12-9 11m136-9-4-2 2-6c2-6 2-7 0-15l-4-14c0-3-4-12-8-20l-8-15v-49l4-4 6-4 7-2c9-5 39 1 44 9 4 7 2 8-6 2-7-5-8-4-14 3-7 9-23 17-31 15-11-3-9 20 4 46a71057 71057 0 0 1 11 25l1 8c1 5 0 7-1 7-1 1 0 2 1 3 5 7 3 17-4 13m2-109c11-6 12-16 1-16-3 0-4 0-5 2-1 4-5 5-8 2-4-4-6-3-9 1-3 7 12 15 21 11M97 210l2-12c1-5 2-8 1-9v-1c2 0 12-15 17-25 8-18 6-39-4-39-12 0-23-6-31-16-7-9-8-9-14-6-5 3-6 2-4-2 4-8 36-11 48-5s13 8 15 30c3 28 3 31-11 54-4 5-5 10-5 12 0 6-6 20-9 21-4 2-5 2-5-2m17-96c6-4 6-7 1-11l-3-4-3 4c-4 4-5 4-7 2-3-3-2-4 2-3h4c0-2-10-4-16-3-10 1-6 11 6 16 7 4 10 4 16-1m56-8-1-26 1-21 1 10 2 12v3l-1 14c-1 9-1 11-2 7z",
        ),
        attribute.attribute("fill", "#536374"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M151 332c-27-3-34-9-34-30 0-31-32-53-61-43-21 8-29 2-42-26-10-23-8-33 9-41 28-16 33-55 8-76-17-13-16-23 3-49 15-19 24-22 41-12 28 17 62 1 69-31 4-20 10-24 37-22 30 2 39 8 39 30 0 31 30 53 61 43 20-7 28-3 39 20 13 28 12 38-5 47-30 16-34 55-9 75 17 13 16 24-2 48-16 21-22 23-42 14-30-16-62-2-69 31-4 20-13 25-42 22m25-11c6-3 8-5 11-21 7-29 44-45 74-31 33 16 62-23 36-50a51 51 0 0 1 10-81c15-10 16-18 6-39-8-18-13-20-30-16-37 8-72-15-72-49 0-15-5-20-23-23-23-5-32-1-37 18-9 34-47 52-77 35-17-9-23-8-35 9-14 19-14 27 0 41 24 25 20 62-9 83-16 11-17 17-8 34 10 19 18 24 32 20 23-5 37-1 57 17 9 8 12 16 14 31 1 13 3 17 9 20 11 5 32 7 42 2m-62-71c0-1 0-4 2-6 4-5 5-5 2 0l-2 5c-1 2-1 2-2 1m112-4c-2-2-2-3-1-4 2-1 3 0 3 4l-1 3zm-113-2 1-1v1l-1 1zm-8-1 2-5c1-2 1-2-2-1-4 2-1-3 3-5 5-3 12 2 9 5l-1 3c0 1 0 2-1 1l-3 1c-2 1-2 1-1-1 1-3 1-3-2 0zm125 0 1-2 2 2-1 1zm-1-5c-6-4-6-5 0-8 4-2 4-2 8 0 4 4 4 8-2 8-3-1-3-1-2 1 3 3 2 3-4-1m-61-1-1-3c2-2-1-6-5-8-3-1-6-4-8-7l-10-9c-5-3-6-5-7-9-1-6 0-8 2-6 2 1 3 0 7-3l5-4 8 2c9 2 15 2 26 0 8-1 9-1 15 2 5 3 6 3 7 1 1-1 1-1 1 2 0 5-3 13-7 14l-11 10-10 8c-1 0-2 1-2 3l-3 3c-1 0-2 1-1 2l2 1c2 0 2 0 0 1-1 2-2 2-4 0-2-3-3-3-2-1 1 3 0 3-2 1m-68 0-1-5c1-3 0-4-1-3-3 1-2-4 1-9l2-4 5 4 3 6c-1 4-9 12-9 11m136-9-4-2 2-6 2-9c-5-19-9-31-13-38-13-23-14-67-2-73 16-8 46-5 53 5 6 8 4 9-5 3-7-5-8-5-15 4-6 9-18 14-30 14-11 0-9 20 4 45 11 24 11 22 11 34l1 11c5 7 2 15-4 12m2-109c8-5 11-11 7-15-3-3-9-2-12 2l-3 4-4-4-4-3-3 3c-7 8 8 18 19 13M97 210l2-11c2-5 2-8 1-9v-2c2 0 12-14 17-24 8-18 6-40-4-40-12 0-24-7-32-17-6-8-7-8-13-5-5 3-6 2-4-3 5-7 37-10 49-3 11 5 12 7 14 31 3 27 2 31-11 52-3 3-5 8-5 11 0 7-6 21-9 22-4 2-5 2-5-2m17-96c6-4 6-7 1-11l-3-4-3 4c-4 4-5 4-7 2-3-2-2-3 2-3 5 1 5-2 0-3-19-3-24 7-7 16 7 4 11 4 17-1m56-11V59l1 11 3 11-1 2-1 12c-1 8-1 10-2 8",
        ),
        attribute.attribute("fill", "#495a6d"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M141 331c-18-4-24-11-24-29 0-32-31-53-62-43-20 7-27 2-38-21-13-27-12-37 5-46 30-16 34-55 9-76-17-13-16-24 3-49 15-19 24-22 41-12 28 17 62 1 69-31 4-20 10-24 37-22 31 2 39 8 39 31 0 31 31 52 61 42 21-8 31-1 43 29 8 22 7 29-9 38-17 10-22 18-24 36-1 20 2 29 15 39 16 12 16 22 1 44-16 24-27 28-44 18-29-17-65-1-70 30-3 21-18 27-52 22m35-10c6-3 8-5 11-21 7-29 45-45 74-31 33 16 62-23 36-50a51 51 0 0 1 10-81c15-10 16-18 6-39-8-18-13-21-30-16-36 9-72-15-72-49 0-17-11-25-37-25-15 0-19 3-23 20-10 34-47 52-77 35-17-10-24-8-37 11-12 19-12 25 2 39 24 25 20 62-9 83-16 11-17 17-8 34 10 19 18 24 32 20 18-4 28-3 42 5 19 12 27 24 29 43 1 13 3 17 9 20 11 5 32 7 42 2m-62-71c-1-2 3-9 4-8l-1 5zm112-4c-1-2-2-3-1-4 2-1 4 2 3 5-1 1-1 1-2-1m-121-3 2-5c1-2 1-2-2-1-3 2-3 2-1-1 4-5 6-6 11-4l4 2-4 5c-3 3-4 4-3 2 0-3 0-3-3 0zm125 0 1-2 2 2-1 1zm-1-5c-6-4-6-5 0-8 4-2 4-2 8 0 4 4 4 7-1 7-4 0-4 1-3 2 3 3 1 3-4-1m-61-1-1-3c2-2-1-6-6-9-3-1-6-4-8-7-2-2-5-6-8-7-6-4-8-7-8-13 0-4 1-5 2-3 2 1 3 1 7-2 4-4 5-4 10-3 14 2 19 2 29 1 9-2 10-2 14 1 3 2 6 3 7 2 1 0 2 0 2 2 0 3-5 13-6 13l-11 9-11 9c-1 0-2 1-2 3l-3 3-2 2-2 1c-1-1-1-1-1 1 1 2 0 2-2 0m6 1h2l-1 1zm-74-3v-5l-2-2c-2 1-1-5 1-9l3-3 4 4c4 4 4 6-2 13-4 5-4 5-4 2m137-7-5-3 2-6c2-5 2-7 0-13l-4-16-7-18c-9-15-10-19-10-42 0-12 1-21 2-22 2-5 7-9 9-9l6-2c9-5 39 1 44 8 6 8 4 9-5 3-7-5-8-5-14 3-7 9-18 15-31 15-5 0-7 5-6 17 0 10 1 12 14 36l5 13 1 3 1 9 2 13v6c4 4 0 8-4 5m1-109c8-5 11-11 7-15-3-3-9-2-12 2l-3 4-4-4-4-3-3 3c-7 8 8 18 19 13M97 210l2-11c1-4 2-8 1-9l6-9c18-23 22-57 7-57-12 0-24-7-32-17-6-7-10-9-13-5-2 2-5 3-5 1 0-10 35-15 50-7 21 10 22 55 3 83-3 3-5 8-5 11 0 7-6 21-9 22-4 2-5 2-5-2m17-96c6-4 6-7 1-11l-3-4-3 4c-4 4-5 4-7 2-3-2-2-3 2-3 5 1 5-2 0-3-19-3-24 7-7 16 7 4 11 4 17-1m56-13V59l1 11 3 11-1 2-1 11c-1 6-1 8-2 7",
        ),
        attribute.attribute("fill", "#365574"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M143 331c-20-4-25-9-26-29-1-33-32-54-63-43-17 7-25 2-37-20-14-28-12-39 8-49 27-14 30-52 5-74-16-15-14-29 9-54 14-15 18-16 37-6 28 15 63-1 68-31 3-21 15-27 46-22 23 3 29 8 30 29 1 32 30 53 61 43 21-7 27-4 39 21 13 28 12 36-9 48-25 14-29 55-6 73 16 12 17 22 3 43-17 24-27 28-46 18-29-16-63 0-69 32-4 21-17 26-50 21m32-9q9-3 12-18c6-33 43-49 77-33 17 8 24 5 36-14 12-17 11-23-3-38-25-26-20-63 9-81 15-9 17-17 9-36s-15-24-32-19c-24 6-39 1-59-18-10-10-12-14-13-30-2-19-7-24-32-25-21-2-23 0-29 20a53 53 0 0 1-77 34c-19-10-27-7-40 19-8 14-7 18 7 32 23 25 18 63-11 82-15 10-16 16-8 33 11 21 18 25 37 21 33-7 64 16 67 47 1 17 4 22 18 25 8 1 26 1 32-1m-61-72c-1-2 3-9 4-8l-1 5zm112-4c-1-2-2-3-1-4 2-1 4 2 3 5-1 1-1 1-2-1m-121-3 2-5c1-2 1-2-2-1-3 2-3 2-1-1 4-5 6-6 11-4l4 2-4 5c-3 3-4 4-3 2 0-3 0-3-3 0zm125 0 1-2 2 2-1 1zm-1-5c-6-4-6-5 0-8 4-2 4-2 8 0 4 4 4 7-1 7-4 0-4 1-3 2 3 3 1 3-4-1m-61-1-1-3c2-2-1-6-6-9-3-1-6-4-8-7-2-2-5-6-8-7-6-4-8-7-8-13 0-4 1-5 2-3 2 1 3 1 7-2 4-4 5-4 10-3 14 2 19 2 29 1 9-2 10-2 14 1 3 2 6 3 7 2 1 0 2 0 2 2 0 3-5 13-6 13l-11 9-11 9c-1 0-2 1-2 3l-3 3-2 2-2 1c-1-1-1-1-1 1 1 2 0 2-2 0m6 1h2l-1 1zm-74-3v-5l-2-2c-2 1-1-5 1-9l3-3 4 4c4 4 4 6-2 13-4 5-4 5-4 2m137-7-5-3 2-6c2-5 2-7 0-13l-4-16-7-18c-9-15-10-19-10-42 0-12 1-21 2-22 2-5 7-9 9-9l6-2c9-5 39 1 44 8 6 8 4 9-5 3-7-5-8-5-14 3-7 9-18 15-31 15-5 0-7 5-6 17 0 10 1 12 14 36l5 13 1 3 1 9 2 13v6c4 4 0 8-4 5m1-109c8-5 11-11 7-15-3-3-9-2-12 2l-3 4-4-4-4-3-3 3c-7 8 8 18 19 13M97 210l2-11c1-4 2-8 1-9l6-9c18-23 22-57 7-57-12 0-24-7-32-17-6-7-10-9-13-5-2 2-5 3-5 1 0-10 35-15 50-7 21 10 22 55 3 83-3 3-5 8-5 11 0 7-6 21-9 22-4 2-5 2-5-2m17-96c6-4 6-7 1-11l-3-4-3 4c-4 4-5 4-7 2-3-2-2-3 2-3 5 1 5-2 0-3-19-3-24 7-7 16 7 4 11 4 17-1m56-13V59l1 11 3 11-1 2-1 11c-1 6-1 8-2 7",
        ),
        attribute.attribute("fill", "#484d50"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M143 331c-20-4-25-9-26-29-1-33-32-54-63-43-17 7-25 2-37-20-14-28-12-39 8-49 27-14 30-52 5-74-16-15-14-29 9-54 14-15 18-16 37-6 28 15 63-1 68-31 3-21 15-27 46-22 23 3 29 8 30 29 1 32 30 53 61 43 21-7 27-4 39 21 13 28 12 36-9 48-25 14-29 55-6 73 16 12 17 22 3 43-17 24-27 28-46 18-29-16-63 0-69 32-4 21-17 26-50 21m32-9q9-3 12-18c6-33 43-49 77-33 17 8 24 5 36-14 12-17 11-23-3-38-25-26-20-63 9-81 15-9 17-17 9-36s-15-24-32-19c-24 6-39 1-59-18-10-10-12-14-13-30-2-19-7-24-32-25-21-2-23 0-29 20a53 53 0 0 1-77 34c-19-10-27-7-40 19-8 14-7 18 7 32 23 25 18 63-11 82-15 10-16 16-8 33 11 21 18 25 37 21 33-7 64 16 67 47 1 17 4 22 18 25 8 1 26 1 32-1m-62-73 3-5c3-3 3-3 1 2-1 3-4 5-4 3m113-3c-1-2-2-3-1-4 2-1 4 2 3 5-1 1-1 1-2-1m-121-3 2-4c1-3 0-4-3-1l1-3c4-5 5-5 10-2l4 1-4 5c-3 3-4 4-3 2 0-3 0-3-3 0zm125 0 1-2 2 2-1 1zm0-4c-6-4-7-7-3-8l4-2c1-1 2-1 5 1 4 4 4 7 0 7s-5 0-2 3c2 2 1 2-4-1m-62-2-1-3c2-2-1-6-6-9-3-1-6-5-8-7-1-3-4-6-7-7q-9-4.5-9-12c0-7.5 1-6 2-4 2 1 3 1 7-2l5-4 11 2c9 2 11 2 21 0 11-2 12-2 16 1 3 2 6 3 7 2 1 0 2 0 2 2 0 3-5 13-7 13l-9 8a1320 1320 0 0 1-24 20m-68-3v-5c2-1 1-1 0-1-4 2-4-1-1-7l2-5 4 4c5 5 5 8-2 13-3 3-3 3-3 1m136-6c-3-2-4-3-3-4 2-3 3-13 2-17l-4-14-9-23-8-16v-23c0-25 1-29 9-32l8-2c4-2 19-1 32 2 7 1 8 2 11 6 5 7 3 8-4 3-8-5-9-5-14 2-7 9-21 16-31 16-6-1-8 4-7 17 0 10 2 14 12 32a87 87 0 0 1 8 20l2 10c0 11 1 18 2 20 2 4-1 6-6 3m7-113c3-3 4-5 3-8 0-5-8-6-13-1l-3 4-4-4c-4-3-6-3-9 2-5 10 16 16 26 7M97 210l2-11 2-9 1-3c20-24 28-70 12-63-7 2-26-7-33-17-5-8-8-9-14-5-4 3-5 2-3-2 4-8 36-11 49-5 11 6 12 8 14 32 3 28 2 31-12 52-3 5-4 8-4 11l-3 11-3 8c-1 4-8 5-8 1m16-95c6-5 7-8 3-12-3-3-7-4-7-2 0 3-4 6-6 4-4-2-4-3 1-3 5 1 5-1 1-2-6-2-18-1-18 0-2 13 15 23 26 15m57-36c0-17 0-18 1-9l3 11c1 1 1 2-1 2l-1 5-1 8c-1 1-2-4-1-17",
        ),
        attribute.attribute("fill", "#254668"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m113 249 3-5c3-3 3-3 1 2-1 3-4 5-4 3m113-3c-1-2-2-3-1-4 2-1 4 2 3 5-1 1-1 1-2-1m-121-3 2-4c1-3 0-4-3-1l1-3c4-5 5-5 10-2l4 1-4 5c-3 3-4 4-3 2 0-3 0-3-3 0zm125 0 1-2 2 2-1 1zm0-4c-6-4-7-7-3-8l4-2c1-1 2-1 5 1 4 4 4 7 0 7s-5 0-2 3c2 2 1 2-4-1m-62-2-1-3c2-2-1-6-6-9-3-1-6-5-8-7-1-3-4-6-7-7q-9-4.5-9-12c0-7.5 1-6 2-4 2 1 3 1 7-2l5-4 11 2c9 2 11 2 21 0 11-2 12-2 16 1 3 2 6 3 7 2 1 0 2 0 2 2 0 3-5 13-7 13l-9 8a1320 1320 0 0 1-24 20m-68-3v-5c2-1 1-1 0-1-4 2-4-1-1-7l2-5 4 4c5 5 5 8-2 13-3 3-3 3-3 1m136-6c-3-2-4-3-3-4 2-3 3-13 2-17l-4-14-9-23-8-16v-23c0-25 1-29 9-32l8-2c4-2 19-1 32 2 7 1 8 2 11 6 5 7 3 8-4 3-8-5-9-5-14 2-7 9-21 16-31 16-6-1-8 4-7 17 0 10 2 14 12 32a87 87 0 0 1 8 20l2 10c0 11 1 18 2 20 2 4-1 6-6 3m7-113c3-3 4-5 3-8 0-5-8-6-13-1l-3 4-4-4c-4-3-6-3-9 2-5 10 16 16 26 7M97 210l2-11 2-9 1-3c20-24 28-70 12-63-7 2-26-7-33-17-5-8-8-9-14-5-4 3-5 2-3-2 4-8 36-11 49-5 11 6 12 8 14 32 3 28 2 31-12 52-3 5-4 8-4 11l-3 11-3 8c-1 4-8 5-8 1m16-95c6-5 7-8 3-12-3-3-7-4-7-2 0 3-4 6-6 4-4-2-4-3 1-3 5 1 5-1 1-2-6-2-18-1-18 0-2 13 15 23 26 15m57-36c0-17 0-18 1-9l3 11c1 1 1 2-1 2l-1 5-1 8c-1 1-2-4-1-17",
        ),
        attribute.attribute("fill", "#3a3e41"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m115 247 2-3c1 1-1 5-3 5zm110-2c-1-2-1-2 1-2l2 2-1 3zm-120-3 2-4c1-2 1-2-1-2-3 2-1-2 2-4 7-4 11 2 6 8-3 3-3 3-2 1 0-3 0-3-2-1-3 3-5 3-5 2m124-4c-5-3-6-6-2-7l4-2c1-1 2-1 5 1 4 4 4 7 0 7-3 0-4 0-3 1 0 2 1 2-4 0m-61-1v-3c1-3-2-7-7-9l-8-7c-1-3-5-6-7-7-7-5-9-7-9-13 0-4 1-5 2-4 2 3 3 2 8-2l4-3 11 2c10 2 12 2 22 0l11-2 4 4c4 2 6 3 7 1 2-1 2-1 1 3-1 7-2 9-10 15l-9 8-6 5-4 4c0 2-2 3-3 3l-2 2c0 1 0 2-1 1l-3 1zm-68-5c1-3 0-4-1-3-3 1-3-2 0-8l3-5 4 4c4 5 3 8-3 14l-3 3zm137-4c-3-3-4-4-2-9 2-9-4-30-13-50l-8-15v-23c0-25 1-29 9-31l7-3c6-3 38 1 41 5 8 10 8 12-1 6-8-5-8-5-16 3-8 10-18 15-29 14-12 0-10 24 4 48a112 112 0 0 1 10 22l1 10a314 314 0 0 0 1 26zm-1-109c6-1 11-7 10-12 0-5-9-6-12-2s-6 4-9 0c-3-3-5-2-8 3-2 5 8 14 14 13zM97 211l2-11 2-10c-1-1 0-2 1-3 9-10 19-28 19-35 2-21 0-28-10-29-13-1-34-14-34-22 0-2-7-1-10 1s-3 2-3 0c0-9 34-13 49-6 10 4 12 8 14 26l2 21c0 6-2 17-5 20l-1 3-6 10c-3 5-6 11-6 14-3 15-14 32-14 21m16-96c7-5 7-15-1-15l-4 3c-1 2-6 3-7 1-1-1 1-1 3-1l4-2c0-3-21-4-22 0-4 10 16 21 27 14m57-36c0-16 0-17 1-9l1 10-1 9-1 9z",
        ),
        attribute.attribute("fill", "#363736"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M115 247c0-2 1-3 2-3l-1 3-2 2zm111-2c-2-2-2-2 0-2l2 2v3zm-121-3 2-3c2-1 1-3-1-2-2 0-2-1 1-3 3-3 4-3 7-2 4 2 4 3 0 6l-1 1c1-3-1-2-5 1-1 2-3 2-3 2m124-4c-5-3-6-6-2-7l4-2c1-1 2-1 5 1 5 4 4 7-1 6-4 0-4 1-3 2 2 2 2 2-3 0m-129-6c1-3 0-4-1-3-4 1-2-8 2-11 4-2 8 6 6 10-4 8-7 9-7 4m67-1c-1-2-2-4-5-5l-8-7-9-9c-6-4-8-6-8-12 0-5 1-5 2-3 2 2 2 2 7-2 6-4 6-4 17-2 8 3 11 2 24 0 6-2 7-1 12 2 5 2 6 3 8 1v3c-1 6-4 11-8 13-5 3-26 23-26 24 0 3-5 1-6-3m69-4c-3-2-3-3-2-5 3-4 2-10 0-19l-4-14-7-18c-10-17-14-56-6-66 8-12 48-12 57 1 5 6 4 7-4 2s-9-5-15 3c-9 10-19 15-30 14-12 0-11 21 2 46a144 144 0 0 1 11 23l2 11 1 17c0 8 0 9-5 5m3-109c5-2 8-7 7-11 0-5-9-6-12-2s-6 4-9 0c-3-3-5-3-7 2-2 4-2 4 2 8 6 7 10 7 19 3M97 211l2-11 2-10v-2c5-2 20-30 21-38 1-19-1-26-9-27-10-1-14-2-18-4-5-3-13-11-16-15-2-5-7-5-12-2-3 2-5-2-1-4 12-10 51-6 57 6 6 11 7 53 2 59-2 1-2 2-2 3l-6 11c-4 6-6 10-6 13l-3 10-3 8c0 1-1 3-4 4s-4 1-4-1m16-96c7-5 6-15-1-15l-4 3c-1 2-6 3-7 1-1-1 1-1 3-1 4 0 5-2 2-4-10-3-22 0-19 7 4 10 17 15 26 9m57-36c0-14 0-16 1-10l1 10c1 1 0 5-1 10-1 8-1 8-1-10",
        ),
        attribute.attribute("fill", "#30302c"),
      ]),
    ],
  )
}

pub fn perl() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 256"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "M255.76 127.76c0 70.559-57.2 127.759-127.76 127.759S.24 198.319.24 127.759 57.44 0 128 0s127.76 57.2 127.76 127.76",
        ),
        attribute.attribute("fill", "#3A3C5B"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M217 137.209c-4.304-27.163-32.802-44.758-54.023-58.028-9.27-5.797-24.3-13.348-26.244-25.54-.802-5.038-.773-10.243-.941-15.33-.067-1.998-.098-4.007-.276-6-.231-2.57-2.847.598-4.281-1.645-3.553-5.554-2.185 1.683-1.836 4.603.822 6.87 1.787 13.718 1.732 20.652-.107 13.251-2.242 25.936-5.546 38.704-7.738 29.899-13.842 60.533-6.187 91.129 1.586 6.34 3.65 12.594 6.363 18.544.82 1.8 2.39 6.821 4.646 7.423 8.126 2.168 14.27 2.796 20.76 8.84 4.03 3.753 7.051 1.703 11.817-.204 14.436-5.777 26.947-13.048 37.176-24.945 14.38-16.724 20.312-36.301 16.84-58.203m-15.268 27.35c-1.28 11.172-8.288 21.18-15.444 29.476-5.188 6.015-12.206 13.82-19.897 16.56-2.769.985.507-4.554.913-5.165 2.38-3.58 5.315-6.738 8.039-10.051 4.03-4.898 7.52-10.04 9.88-15.972 7.832-19.688 6.052-43.552-5.539-61.289-6.31-9.656-14.972-17.818-23.703-25.265-4.218-3.598-8.486-7-12.036-11.304-.82-.995-8.07-10.485-5.815-11.889.728-.453 16.573 16.214 18.297 17.515 6.552 4.947 13.29 9.522 19.357 15.093 8.21 7.543 16.642 15.968 21.346 26.226 5.155 11.24 5.994 23.911 4.602 36.064",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M123.294 3.443c2.379 1.587 2.907 10.836 2.907 19.293 0 8.458.793 44.93-1.85 54.709-2.642 9.779-8.721 20.615-15.329 30.13-6.607 9.514-14.271 29.6-14.007 42.02.264 12.424 7.4 32.773 12.95 41.23 5.571 8.49 15.029 20.322 12.95 22.995-3.7 4.757-18.764-11.63-26.693-21.143-7.929-9.515-15.858-28.81-16.121-43.873-.265-15.065 8.192-29.073 14.271-37.53s17.972-22.993 21.143-29.6 6.608-13.743 7.665-22.994 0-42.287 0-42.287-.265-14.536 2.114-12.95",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M116.951 19.036c2.378 1.058 2.643 3.965 2.643 6.872s-.793 14.8-1.586 26.43c-.793 11.628-10.042 21.407-16.914 28.278C94.222 87.488 74.4 108.896 67 119.468s-11.088 24.496-10.307 36.207c.792 11.893 3.7 23.522 14.8 35.944s18.765 18.236 24.579 21.144c5.815 2.905 11.63 5.02 10.308 7.664-1.322 2.642-6.873.792-12.951-1.321-6.079-2.116-26.693-10.571-38.587-24.05-11.892-13.48-17.97-31.452-17.442-48.632.527-17.178 5.286-24.314 13.214-35.414S80.48 83.524 87.35 79.296c6.872-4.23 16.122-11.365 20.616-17.18 4.492-5.814 6.87-10.572 6.606-18.5s.53-15.065.265-17.708-.265-7.928 2.114-6.872M117.613 226.203c1.075-.043.396 4.614-1.502 6.925s-5.157 3.7-5.553 2.77c-.398-.93 2.353-1.465 4.373-3.713 1.855-2.064 1.364-5.929 2.682-5.982M139.003 226.08c-1.074-.044-.395 4.613 1.503 6.923s5.157 3.701 5.552 2.772c.398-.93-2.353-1.465-4.373-3.713-1.855-2.063-1.364-5.93-2.682-5.981M129.495 231.133c0 4.067.207 7.364-.68 7.364-1.094 0-.682-3.297-.682-7.364s-.37-7.365.681-7.365c.97 0 .68 3.298.68 7.365",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
    ],
  )
}

pub fn php() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 135"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.defs([], [
        svg.radial_gradient(
          [
            attribute.attribute("gradientUnits", "userSpaceOnUse"),
            attribute.attribute(
              "gradientTransform",
              "translate(76.464 81.918)scale(.463)",
            ),
            attribute.attribute("r", "363.057"),
            attribute.attribute("cy", "-125.811"),
            attribute.attribute("cx", ".837"),
            attribute.id("a"),
          ],
          [
            svg.stop([
              attribute.attribute("style", "stop-color:#fff"),
              attribute.attribute("offset", "0"),
            ]),
            svg.stop([
              attribute.attribute("style", "stop-color:#4c6b97"),
              attribute.attribute("offset", ".5"),
            ]),
            svg.stop([
              attribute.attribute("style", "stop-color:#231f20"),
              attribute.attribute("offset", "1"),
            ]),
          ],
        ),
      ]),
      svg.ellipse([
        attribute.attribute("ry", "67.3"),
        attribute.attribute("rx", "128"),
        attribute.attribute("fill", "url(#a)"),
        attribute.attribute("cy", "67.3"),
        attribute.attribute("cx", "128"),
      ]),
      svg.ellipse([
        attribute.attribute("ry", "62.3"),
        attribute.attribute("rx", "123"),
        attribute.attribute("fill", "#6181B6"),
        attribute.attribute("cy", "67.3"),
        attribute.attribute("cx", "128"),
      ]),
      svg.g([attribute.attribute("fill", "#FFF")], [
        svg.path([
          attribute.attribute(
            "d",
            "m152.9 87.5 6.1-31.4c1.4-7.1.2-12.4-3.4-15.7-3.5-3.2-9.5-4.8-18.3-4.8h-10.6l3-15.6c.1-.6 0-1.2-.4-1.7s-.9-.7-1.5-.7h-14.6c-1 0-1.8.7-2 1.6l-6.5 33.3c-.6-3.8-2-7-4.4-9.6-4.3-4.9-11-7.4-20.1-7.4H52.1c-1 0-1.8.7-2 1.6L37 104.7c-.1.6 0 1.2.4 1.7s.9.7 1.5.7h14.7c1 0 1.8-.7 2-1.6l3.2-16.3h10.9c5.7 0 10.6-.6 14.3-1.8q5.85-1.95 10.5-6.3c2.5-2.3 4.6-4.9 6.2-7.7l-2.6 13.5c-.1.6 0 1.2.4 1.7s.9.7 1.5.7h14.6c1 0 1.8-.7 2-1.6l7.2-37h10c4.3 0 5.5.8 5.9 1.2.3.3.9 1.5.2 5.2L134.1 87c-.1.6 0 1.2.4 1.7s.9.7 1.5.7h15c.9-.3 1.7-1 1.9-1.9m-67.6-26c-.9 4.7-2.6 8.1-5.1 10s-6.6 2.9-12 2.9h-6.5l4.7-24.2h8.4c6.2 0 8.7 1.3 9.7 2.4 1.3 1.6 1.6 4.7.8 8.9M215.3 42.9c-4.3-4.9-11-7.4-20.1-7.4h-28.3c-1 0-1.8.7-2 1.6l-13.1 67.5c-.1.6 0 1.2.4 1.7s.9.7 1.5.7h14.7c1 0 1.8-.7 2-1.6l3.2-16.3h10.9c5.7 0 10.6-.6 14.3-1.8q5.85-1.95 10.5-6.3c2.6-2.4 4.8-5.1 6.4-8s2.8-6.1 3.5-9.6c1.7-8.7.4-15.5-3.9-20.5M200 61.5c-.9 4.7-2.6 8.1-5.1 10s-6.6 2.9-12 2.9h-6.5l4.7-24.2h8.4c6.2 0 8.7 1.3 9.7 2.4 1.4 1.6 1.7 4.7.8 8.9",
          ),
        ]),
      ]),
      svg.g([attribute.attribute("fill", "#000004")], [
        svg.path([
          attribute.attribute(
            "d",
            "M74.8 48.2c5.6 0 9.3 1 11.2 3.1s2.3 5.6 1.3 10.6c-1 5.2-3 9-5.9 11.2q-4.35 3.3-13.2 3.3h-8.9l5.5-28.2zM39 105h14.7l3.5-17.9h12.6c5.6 0 10.1-.6 13.7-1.8s6.8-3.1 9.8-5.9q3.75-3.45 6-7.5c1.5-2.7 2.6-5.7 3.2-9 1.6-8 .4-14.2-3.5-18.7s-10.1-6.7-18.6-6.7H52.1zM113.3 19.6h14.6l-3.5 17.9h13c8.2 0 13.8 1.4 16.9 4.3s4 7.5 2.8 13.9L151 87.1h-14.8l5.8-29.9c.7-3.4.4-5.7-.7-6.9s-3.6-1.9-7.3-1.9h-11.7l-7.5 38.7h-14.6zM189.5 48.2c5.6 0 9.3 1 11.2 3.1s2.3 5.6 1.3 10.6c-1 5.2-3 9-5.9 11.2q-4.35 3.3-13.2 3.3H174l5.5-28.2zM153.7 105h14.7l3.5-17.9h12.6c5.6 0 10.1-.6 13.7-1.8s6.8-3.1 9.8-5.9q3.75-3.45 6-7.5c1.5-2.7 2.6-5.7 3.2-9 1.6-8 .4-14.2-3.5-18.7s-10.1-6.7-18.6-6.7h-28.3z",
          ),
        ]),
      ]),
    ],
  )
}

pub fn python() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 255"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.defs([], [
        svg.linear_gradient(
          [
            attribute.attribute("y2", "78.201%"),
            attribute.attribute("y1", "12.039%"),
            attribute.attribute("x2", "79.639%"),
            attribute.attribute("x1", "12.959%"),
            attribute.id("pythonGradient1"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#387EB8"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#366994"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "88.429%"),
            attribute.attribute("y1", "20.579%"),
            attribute.attribute("x2", "90.742%"),
            attribute.attribute("x1", "19.128%"),
            attribute.id("pythonGradient2"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#FFE052"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#FFC331"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M126.916.072c-64.832 0-60.784 28.115-60.784 28.115l.072 29.128h61.868v8.745H41.631S.145 61.355.145 126.77c0 65.417 36.21 63.097 36.21 63.097h21.61v-30.356s-1.165-36.21 35.632-36.21h61.362s34.475.557 34.475-33.319V33.97S194.67.072 126.916.072M92.802 19.66a11.12 11.12 0 0 1 11.13 11.13 11.12 11.12 0 0 1-11.13 11.13 11.12 11.12 0 0 1-11.13-11.13 11.12 11.12 0 0 1 11.13-11.13",
        ),
        attribute.attribute("fill", "url(#pythonGradient1)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M128.757 254.126c64.832 0 60.784-28.115 60.784-28.115l-.072-29.127H127.6v-8.745h86.441s41.486 4.705 41.486-60.712c0-65.416-36.21-63.096-36.21-63.096h-21.61v30.355s1.165 36.21-35.632 36.21h-61.362s-34.475-.557-34.475 33.32v56.013s-5.235 33.897 62.518 33.897m34.114-19.586a11.12 11.12 0 0 1-11.13-11.13 11.12 11.12 0 0 1 11.13-11.131 11.12 11.12 0 0 1 11.13 11.13 11.12 11.12 0 0 1-11.13 11.13",
        ),
        attribute.attribute("fill", "url(#pythonGradient2)"),
      ]),
    ],
  )
}

pub fn raku() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "22 40 948 693"),
      attribute.attribute("version", "1.0"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.defs([], [
        element.element("clippath", [attribute.id("a")], [
          svg.path([attribute.attribute("d", "M0-.1h792.1V612H0z")]),
        ]),
      ]),
      svg.g(
        [
          attribute.attribute("transform", "matrix(1.25 0 0 -1.25 0 765)"),
          attribute.attribute("clip-path", "url(#a)"),
        ],
        [
          svg.path([
            attribute.attribute(
              "style",
              "fill:#000;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M304.2 75.7c-55.4-40.6-129.5-33.6-165.6 15.7-36 49.2-20.3 122 35.1 162.5 55.3 40.6 129.5 33.6 165.5-15.6 36.1-49.3 20.4-122.1-35-162.6",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#000;stroke-width:4.30158997;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M304.2 75.7c-55.4-40.6-129.5-33.6-165.6 15.7-36 49.2-20.3 122 35.1 162.5 55.3 40.6 129.5 33.6 165.5-15.6 36.1-49.3 20.4-122.1-35-162.6z",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#000;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M273.6 523.5c68.9-50.4 88.4-140.9 43.5-202.1-44.8-61.2-137-69.9-205.8-19.5-68.9 50.4-88.4 141-43.6 202.2 44.9 61.2 137 69.9 205.9 19.4",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#000;stroke-width:7.1882;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M273.6 523.5c68.9-50.4 88.4-140.9 43.5-202.1-44.8-61.2-137-69.9-205.8-19.5-68.9 50.4-88.4 141-43.6 202.2 44.9 61.2 137 69.9 205.9 19.4z",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#0f0;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M213.3 370.5c-25.8 21.2-27.3 62.2-3.3 91.4 24.1 29.3 64.5 35.9 90.3 14.6 25.9-21.2 27.4-62.1 3.3-91.4-24-29.3-64.4-35.8-90.3-14.6",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M213.3 370.5c-25.8 21.2-27.3 62.2-3.3 91.4 24.1 29.3 64.5 35.9 90.3 14.6 25.9-21.2 27.4-62.1 3.3-91.4-24-29.3-64.4-35.8-90.3-14.6",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#000;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M191.7 375.8c-25.9 21.3-27.4 62.2-3.4 91.5 24.1 29.3 64.6 35.8 90.4 14.6 25.9-21.2 27.4-62.2 3.3-91.5-24-29.3-64.5-35.8-90.3-14.6",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M191.7 375.8c-25.9 21.3-27.4 62.2-3.4 91.5 24.1 29.3 64.6 35.8 90.4 14.6 25.9-21.2 27.4-62.2 3.3-91.5-24-29.3-64.5-35.8-90.3-14.6",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#00f;stroke-width:21.56459045;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M245.6 311.6c-41.6 27.7-99.1 49.2-123.8 86.2-18.4 27.5-39.3 38.3-17.3 65.5 21 25.7 32.7 53.3 61.9 57.9 32.8-4.4 58.3-7.3 79.3-43.8-2.4-21.4 4.8-66.6-23-88.1l-48.1-26.7",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#f36;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M175 400.5c-23.8 0-43.1 18.9-43.1 42.3s19.3 42.3 43.1 42.3 43.1-18.9 43.1-42.3-19.3-42.3-43.1-42.3",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M175 400.5c-23.8 0-43.1 18.9-43.1 42.3s19.3 42.3 43.1 42.3 43.1-18.9 43.1-42.3-19.3-42.3-43.1-42.3",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#00f;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M194.2 418.9c-8.9-7.3-22.2-5.9-29.7 3.2s-6.3 22.4 2.7 29.7c8.9 7.3 22.2 5.9 29.6-3.2 7.5-9.1 6.3-22.4-2.6-29.7",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M194.2 418.9c-8.9-7.3-22.2-5.9-29.7 3.2s-6.3 22.4 2.7 29.7c8.9 7.3 22.2 5.9 29.6-3.2 7.5-9.1 6.3-22.4-2.6-29.7",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#00f;stroke-width:21.56459045;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M249.3 308.8c-41.7 27.8-104.7 27.8-129.4 64.7-18.4 27.6-50.3 63.1-28.3 90.2 20.1 31.9 45.6 53.8 77.5 53.8 32.9-4.3 66.7-17 74.7-42.8-2.3-21.5 2.1-55.4-25.7-76.9l-45.3-36.1",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#00f;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M268 298c-2.9-5.1-15.3-3.4-27.6 3.7-12.4 7.1-20 17-17.1 22.1 3 5 15.3 3.4 27.7-3.7 12.3-7.2 20-17 17-22.1",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M268 298c-2.9-5.1-15.3-3.4-27.6 3.7-12.4 7.1-20 17-17.1 22.1 3 5 15.3 3.4 27.7-3.7 12.3-7.2 20-17 17-22.1",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#000;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M629.1 253c55.3-40.5 71-113.4 34.9-162.6-36.1-49.3-110.2-56.3-165.6-15.8-55.3 40.6-71 113.4-34.9 162.6 36.1 49.3 110.2 56.4 165.6 15.8",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#000;stroke-width:4.30158997;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M629.1 253c55.3-40.5 71-113.4 34.9-162.6-36.1-49.3-110.2-56.3-165.6-15.8-55.3 40.6-71 113.4-34.9 162.6 36.1 49.3 110.2 56.4 165.6 15.8z",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#ff0;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M399.5 162c-64 0-115.8 41.4-115.8 92.6 0 51.1 51.8 92.6 115.8 92.6s115.8-41.5 115.8-92.6c0-51.2-51.8-92.6-115.8-92.6",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#000;stroke-width:8.63150024;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M399.5 162c-64 0-115.8 41.4-115.8 92.6 0 51.1 51.8 92.6 115.8 92.6s115.8-41.5 115.8-92.6c0-51.2-51.8-92.6-115.8-92.6z",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#fff;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M320.1 255.7c-25.6 0-46.3 20.8-46.3 46.3 0 25.6 20.7 46.3 46.3 46.3s46.4-20.7 46.4-46.3c0-25.5-20.8-46.3-46.4-46.3",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#000;stroke-width:10.07479;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M320.1 255.7c-25.6 0-46.3 20.8-46.3 46.3 0 25.6 20.7 46.3 46.3 46.3s46.4-20.7 46.4-46.3c0-25.5-20.8-46.3-46.4-46.3z",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#000;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M683.4 296.3c-68.4-50.1-160-41.4-204.5 19.4-44.6 60.8-25.2 150.7 43.2 200.9 68.4 50.1 160 41.4 204.5-19.4 44.6-60.9 25.2-150.8-43.2-200.9",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#000;stroke-width:7.1882;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M683.4 296.3c-68.4-50.1-160-41.4-204.5 19.4-44.6 60.8-25.2 150.7 43.2 200.9 68.4 50.1 160 41.4 204.5-19.4 44.6-60.9 25.2-150.8-43.2-200.9z",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#0f0;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M698.5 335.2c-25.7-21.1-65.9-14.5-89.8 14.6s-22.5 69.8 3.2 90.9 65.9 14.6 89.8-14.6c23.9-29.1 22.5-69.8-3.2-90.9",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M698.5 335.2c-25.7-21.1-65.9-14.5-89.8 14.6s-22.5 69.8 3.2 90.9 65.9 14.6 89.8-14.6c23.9-29.1 22.5-69.8-3.2-90.9",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#000;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M677.1 335.2c-25.7-21.1-65.9-14.5-89.8 14.6s-22.5 69.8 3.2 90.8c25.7 21.1 65.9 14.6 89.8-14.5s22.4-69.8-3.2-90.9",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M677.1 335.2c-25.7-21.1-65.9-14.5-89.8 14.6s-22.5 69.8 3.2 90.8c25.7 21.1 65.9 14.6 89.8-14.5s22.4-69.8-3.2-90.9",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#00f;stroke-width:21.56459045;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M705.7 464.7c-18 58.1-98.5 38.2-128.5 18.1-41.4-27.6-36.2-22.1-60.7-58.8-18.3-27.5-8.4-63.6 13.5-90.6 20.7-25.6 29-13.8 61.6-9.5s41.5 5.4 49.4 31c9.9 32.1-22.1 65.3-49.7 86.6L560.2 463",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#f36;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M569.2 345.3c-21 0-37.9 17.2-37.9 38.5s16.9 38.5 37.9 38.5c20.9 0 37.8-17.2 37.8-38.5s-16.9-38.5-37.8-38.5",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M569.2 345.3c-21 0-37.9 17.2-37.9 38.5s16.9 38.5 37.9 38.5c20.9 0 37.8-17.2 37.8-38.5s-16.9-38.5-37.8-38.5",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#00f;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M582.5 361.7c-8.9-7.2-22.1-5.8-29.5 3.3-7.4 9-6.3 22.3 2.5 29.5 8.8 7.3 22.1 5.8 29.5-3.2 7.4-9.1 6.3-22.3-2.5-29.6",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M582.5 361.7c-8.9-7.2-22.1-5.8-29.5 3.3-7.4 9-6.3 22.3 2.5 29.5 8.8 7.3 22.1 5.8 29.5-3.2 7.4-9.1 6.3-22.3-2.5-29.6",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#00f;stroke-width:21.56459045;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M711.2 466.5c-18 58.1-116.7 47.3-146.7 27.2-41.4-27.6-35.3-22.2-59.8-58.9-18.3-27.4-2-76.9 19.9-103.9 20.7-25.6 35.8-19.8 68.3-15.5 32.6 4.3 44 3.5 52 29.2 9.9 32 4 71.5-23.7 92.9l-61 25.5",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#fff;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M473.4 255.7c-25.6 0-46.4 20.8-46.4 46.3 0 25.6 20.8 46.3 46.4 46.3s46.3-20.7 46.3-46.3c0-25.5-20.7-46.3-46.3-46.3",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#000;stroke-width:10.07479;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M473.4 255.7c-25.6 0-46.4 20.8-46.4 46.3 0 25.6 20.8 46.3 46.4 46.3s46.3-20.7 46.3-46.3c0-25.5-20.7-46.3-46.3-46.3z",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#000;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M321.5 279c-12.8 0-23.2 10.4-23.2 23.2s10.4 23.2 23.2 23.2 23.1-10.4 23.1-23.2-10.3-23.2-23.1-23.2",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M321.5 279c-12.8 0-23.2 10.4-23.2 23.2s10.4 23.2 23.2 23.2 23.1-10.4 23.1-23.2-10.3-23.2-23.1-23.2",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#000;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M475.1 281.6c-12.9 0-23.2 10.4-23.2 23.1 0 12.8 10.3 23.1 23.2 23.1 12.8 0 23.1-10.3 23.1-23.1 0-12.7-10.3-23.1-23.1-23.1",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M475.1 281.6c-12.9 0-23.2 10.4-23.2 23.1 0 12.8 10.3 23.1 23.2 23.1 12.8 0 23.1-10.3 23.1-23.1 0-12.7-10.3-23.1-23.1-23.1",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#f36;stroke-width:12.93309021;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M360 230c-4.6-31.7 87.5-54.6 76.4-5.4v2.7",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#000;stroke-width:10.07479;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M385.1 348c-1.9 25.2 7.3 53.8-4.2 77.1l-9.7 23.1-12.6-21.2 9.7-1.9M413.3 348c1.9 25.2-7.4 53.8 4.1 77.1l9.7 23.1 12.6-21.2-9.7-1.9",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#f36;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M181.1 99.3c-26.6 21.9-27.5 64.8-2 96 25.6 31.1 67.9 38.6 94.6 16.7 26.6-21.9 27.5-64.8 1.9-95.9-25.5-31.2-67.8-38.7-94.5-16.8",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M181.1 99.3c-26.6 21.9-27.5 64.8-2 96 25.6 31.1 67.9 38.6 94.6 16.7 26.6-21.9 27.5-64.8 1.9-95.9-25.5-31.2-67.8-38.7-94.5-16.8",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:none;stroke:#000;stroke-width:8.63150024;stroke-linecap:butt;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1",
            ),
            attribute.attribute(
              "d",
              "M375.5 161v-29.9l16.4-27.2M412 161v-30l16.4-27.2",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#00f;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M212.3 134.8c-12 9.8-10.1 32 4.3 49.5 14.4 17.6 35.7 23.8 47.8 13.9 11.9-9.8 10-32-4.3-49.6-14.4-17.5-35.8-23.7-47.8-13.8",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M212.3 134.8c-12 9.8-10.1 32 4.3 49.5 14.4 17.6 35.7 23.8 47.8 13.9 11.9-9.8 10-32-4.3-49.6-14.4-17.5-35.8-23.7-47.8-13.8",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#f36;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M616.6 99.2c-26.7-21.9-69-14.4-94.6 16.8-25.5 31.1-24.6 74.1 2 95.9 26.7 21.9 69 14.4 94.6-16.7 25.5-31.2 24.6-74.1-2-96",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M616.6 99.2c-26.7-21.9-69-14.4-94.6 16.8-25.5 31.1-24.6 74.1 2 95.9 26.7 21.9 69 14.4 94.6-16.7 25.5-31.2 24.6-74.1-2-96",
            ),
          ]),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#00f;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M581.8 132c-12-9.8-33.4-3.6-47.7 13.8-14.4 17.5-16.3 39.7-4.2 49.5 11.9 9.9 33.3 3.7 47.7-13.8 14.3-17.4 16.2-39.6 4.2-49.5",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M581.8 132c-12-9.8-33.4-3.6-47.7 13.8-14.4 17.5-16.3 39.7-4.2 49.5 11.9 9.9 33.3 3.7 47.7-13.8 14.3-17.4 16.2-39.6 4.2-49.5",
            ),
          ]),
          svg.text(
            [attribute.attribute("transform", "matrix(1 0 0 -1 658.4 245.8)")],
            "",
          ),
          svg.path([
            attribute.attribute(
              "style",
              "fill:#00f;fill-opacity:1;fill-rule:evenodd;stroke:none",
            ),
            attribute.attribute(
              "d",
              "M722.4 447.3c-6.1-4.2-19.3 4.3-29.6 19.1-10.4 14.7-13.8 30.1-7.8 34.3s19.3-4.3 29.6-19.1c10.3-14.7 13.8-30.1 7.8-34.3",
            ),
          ]),
          svg.path([
            attribute.attribute("style", "fill:none;stroke:none"),
            attribute.attribute(
              "d",
              "M722.4 447.3c-6.1-4.2-19.3 4.3-29.6 19.1-10.4 14.7-13.8 30.1-7.8 34.3s19.3-4.3 29.6-19.1c10.3-14.7 13.8-30.1 7.8-34.3",
            ),
          ]),
        ],
      ),
    ],
  )
}

pub fn ruby() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 255"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.defs([], [
        svg.linear_gradient(
          [
            attribute.attribute("y2", "64.584%"),
            attribute.attribute("y1", "111.399%"),
            attribute.attribute("x2", "58.254%"),
            attribute.attribute("x1", "84.75%"),
            attribute.id("rubyGradient1"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#FB7655"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#FB7655"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#E42B1E"),
              attribute.attribute("offset", "41%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#900"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#900"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "19.288%"),
            attribute.attribute("y1", "60.89%"),
            attribute.attribute("x2", "1.746%"),
            attribute.attribute("x1", "116.651%"),
            attribute.id("rubyGradient2"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#871101"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#871101"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#911209"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#911209"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "7.829%"),
            attribute.attribute("y1", "219.327%"),
            attribute.attribute("x2", "38.978%"),
            attribute.attribute("x1", "75.774%"),
            attribute.id("rubyGradient3"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#871101"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#871101"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#911209"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#911209"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "79.135%"),
            attribute.attribute("y1", "7.234%"),
            attribute.attribute("x2", "66.483%"),
            attribute.attribute("x1", "50.012%"),
            attribute.id("rubyGradient4"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#E57252"),
              attribute.attribute("offset", "23%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#DE3B20"),
              attribute.attribute("offset", "46%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A60003"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A60003"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "83.047%"),
            attribute.attribute("y1", "16.348%"),
            attribute.attribute("x2", "49.932%"),
            attribute.attribute("x1", "46.174%"),
            attribute.id("rubyGradient5"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#E4714E"),
              attribute.attribute("offset", "23%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#BE1A0D"),
              attribute.attribute("offset", "56%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A80D00"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A80D00"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "92.478%"),
            attribute.attribute("y1", "15.594%"),
            attribute.attribute("x2", "49.528%"),
            attribute.attribute("x1", "36.965%"),
            attribute.id("rubyGradient6"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#E46342"),
              attribute.attribute("offset", "18%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#C82410"),
              attribute.attribute("offset", "40%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A80D00"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A80D00"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "-46.717%"),
            attribute.attribute("y1", "58.346%"),
            attribute.attribute("x2", "85.764%"),
            attribute.attribute("x1", "13.609%"),
            attribute.id("rubyGradient7"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#C81F11"),
              attribute.attribute("offset", "54%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#BF0905"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#BF0905"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "79.056%"),
            attribute.attribute("y1", "21.135%"),
            attribute.attribute("x2", "50.745%"),
            attribute.attribute("x1", "27.624%"),
            attribute.id("rubyGradient8"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#DE4024"),
              attribute.attribute("offset", "31%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#BF190B"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#BF190B"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "-6.342%"),
            attribute.attribute("y1", "122.282%"),
            attribute.attribute("x2", "104.242%"),
            attribute.attribute("x1", "-20.667%"),
            attribute.id("rubyGradient9"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#BD0012"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#BD0012"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "7%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#FFF"),
              attribute.attribute("offset", "17%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#C82F1C"),
              attribute.attribute("offset", "27%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#820C01"),
              attribute.attribute("offset", "33%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A31601"),
              attribute.attribute("offset", "46%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#B31301"),
              attribute.attribute("offset", "72%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#E82609"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#E82609"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "50.128%"),
            attribute.attribute("y1", "65.205%"),
            attribute.attribute("x2", "11.964%"),
            attribute.attribute("x1", "58.792%"),
            attribute.id("rubyGradient10"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#8C0C01"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#8C0C01"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#990C00"),
              attribute.attribute("offset", "54%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A80D0E"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A80D0E"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "17.888%"),
            attribute.attribute("y1", "62.754%"),
            attribute.attribute("x2", "23.088%"),
            attribute.attribute("x1", "79.319%"),
            attribute.id("rubyGradient11"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#7E110B"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#7E110B"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#9E0C00"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#9E0C00"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "39.704%"),
            attribute.attribute("y1", "74.122%"),
            attribute.attribute("x2", "59.841%"),
            attribute.attribute("x1", "92.88%"),
            attribute.id("rubyGradient12"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#79130D"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#79130D"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#9E120B"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#9E120B"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "11.993%"),
            attribute.attribute("y1", "101.717%"),
            attribute.attribute("x2", "3.105%"),
            attribute.attribute("x1", "56.57%"),
            attribute.id("rubyGradient15"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#8B2114"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#8B2114"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#9E100A"),
              attribute.attribute("offset", "43%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#B3100C"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#B3100C"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "100.694%"),
            attribute.attribute("y1", "35.599%"),
            attribute.attribute("x2", "92.471%"),
            attribute.attribute("x1", "30.87%"),
            attribute.id("rubyGradient16"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#B31000"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#B31000"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#910F08"),
              attribute.attribute("offset", "44%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#791C12"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#791C12"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.radial_gradient(
          [
            attribute.attribute("fy", "40.21%"),
            attribute.attribute("fx", "32.001%"),
            attribute.attribute("r", "69.573%"),
            attribute.attribute("cy", "40.21%"),
            attribute.attribute("cx", "32.001%"),
            attribute.id("rubyGradient13"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#A80D00"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A80D00"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#7E0E08"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#7E0E08"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
        svg.radial_gradient(
          [
            attribute.attribute("fy", "40.86%"),
            attribute.attribute("fx", "13.549%"),
            attribute.attribute("r", "88.386%"),
            attribute.attribute("cy", "40.86%"),
            attribute.attribute("cx", "13.549%"),
            attribute.id("rubyGradient14"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#A30C00"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#A30C00"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#800E08"),
              attribute.attribute("offset", "99%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "#800E08"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m197.467 167.764-145.52 86.41 188.422-12.787L254.88 51.393z",
        ),
        attribute.attribute("fill", "url(#rubyGradient1)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M240.677 241.257 224.482 129.48l-44.113 58.25z",
        ),
        attribute.attribute("fill", "url(#rubyGradient2)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m240.896 241.257-118.646-9.313-69.674 21.986z",
        ),
        attribute.attribute("fill", "url(#rubyGradient3)"),
      ]),
      svg.path([
        attribute.attribute("d", "m52.744 253.955 29.64-97.1L17.16 170.8z"),
        attribute.attribute("fill", "url(#rubyGradient4)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M180.358 188.05 153.085 81.226l-78.047 73.16z",
        ),
        attribute.attribute("fill", "url(#rubyGradient5)"),
      ]),
      svg.path([
        attribute.attribute("d", "m248.693 82.73-73.777-60.256-20.544 66.418z"),
        attribute.attribute("fill", "url(#rubyGradient6)"),
      ]),
      svg.path([
        attribute.attribute("d", "M214.191.99 170.8 24.97 143.424.669z"),
        attribute.attribute("fill", "url(#rubyGradient7)"),
      ]),
      svg.path([
        attribute.attribute("d", "m0 203.372 18.177-33.151-14.704-39.494z"),
        attribute.attribute("fill", "url(#rubyGradient8)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m2.496 129.48 14.794 41.963 64.283-14.422 73.39-68.207 20.712-65.787L143.063 0 87.618 20.75c-17.469 16.248-51.366 48.396-52.588 49-1.21.618-22.384 40.639-32.534 59.73",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M54.442 54.094c37.86-37.538 86.667-59.716 105.397-40.818 18.72 18.898-1.132 64.823-38.992 102.349-37.86 37.525-86.062 60.925-104.78 42.027-18.73-18.885.515-66.032 38.375-103.558",
        ),
        attribute.attribute("fill", "url(#rubyGradient9)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m52.744 253.916 29.408-97.409 97.665 31.376c-35.312 33.113-74.587 61.106-127.073 66.033",
        ),
        attribute.attribute("fill", "url(#rubyGradient10)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m155.092 88.622 25.073 99.313c29.498-31.016 55.972-64.36 68.938-105.603z",
        ),
        attribute.attribute("fill", "url(#rubyGradient11)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M248.847 82.833c10.035-30.282 12.35-73.725-34.966-81.791l-38.825 21.445z",
        ),
        attribute.attribute("fill", "url(#rubyGradient12)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M0 202.935c1.39 49.979 37.448 50.724 52.808 51.162l-35.48-82.86z",
        ),
        attribute.attribute("fill", "#9E1209"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M155.232 88.777c22.667 13.932 68.35 41.912 69.276 42.426 1.44.81 19.695-30.784 23.838-48.64z",
        ),
        attribute.attribute("fill", "url(#rubyGradient13)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m82.113 156.507 39.313 75.848c23.246-12.607 41.45-27.967 58.121-44.42z",
        ),
        attribute.attribute("fill", "url(#rubyGradient14)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m17.174 171.34-5.57 66.328c10.51 14.357 24.97 15.605 40.136 14.486-10.973-27.311-32.894-81.92-34.566-80.814",
        ),
        attribute.attribute("fill", "url(#rubyGradient15)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "m174.826 22.654 78.1 10.96c-4.169-17.662-16.969-29.06-38.787-32.623z",
        ),
        attribute.attribute("fill", "url(#rubyGradient16)"),
      ]),
    ],
  )
}

pub fn rust() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 256"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "d",
          "m254.251 124.862-10.747-6.653a146 146 0 0 0-.306-3.13l9.236-8.615a3.69 3.69 0 0 0 1.105-3.427 3.69 3.69 0 0 0-2.33-2.744l-11.807-4.415a137 137 0 0 0-.925-3.048l7.365-10.229a3.698 3.698 0 0 0-2.407-5.814l-12.45-2.025c-.484-.944-.988-1.874-1.496-2.796l5.231-11.483a3.68 3.68 0 0 0-.288-3.59 3.68 3.68 0 0 0-3.204-1.642l-12.636.44a100 100 0 0 0-1.996-2.421l2.904-12.308a3.7 3.7 0 0 0-.986-3.466 3.7 3.7 0 0 0-3.464-.986l-12.305 2.901a106 106 0 0 0-2.426-1.996l.442-12.635a3.68 3.68 0 0 0-1.64-3.205 3.69 3.69 0 0 0-3.59-.29l-11.48 5.234a133 133 0 0 0-2.796-1.5l-2.03-12.452a3.7 3.7 0 0 0-5.812-2.407l-10.236 7.365q-1.51-.481-3.042-.922L155.72 4.794a3.69 3.69 0 0 0-2.745-2.336 3.71 3.71 0 0 0-3.424 1.106l-8.615 9.243a111 111 0 0 0-3.13-.306l-6.653-10.75a3.698 3.698 0 0 0-6.289 0l-6.653 10.75a110 110 0 0 0-3.133.306l-8.617-9.243a3.695 3.695 0 0 0-6.169 1.23l-4.414 11.809c-1.023.293-2.035.604-3.045.922L82.599 10.16a3.69 3.69 0 0 0-3.579-.415 3.7 3.7 0 0 0-2.235 2.822l-2.03 12.452c-.94.487-1.869.988-2.796 1.5l-11.481-5.235a3.69 3.69 0 0 0-3.588.291 3.68 3.68 0 0 0-1.642 3.205l.44 12.635a118 118 0 0 0-2.426 1.996l-12.305-2.9a3.71 3.71 0 0 0-3.466.985 3.7 3.7 0 0 0-.986 3.466l2.899 12.308q-1.01 1.196-1.991 2.421l-12.636-.44a3.72 3.72 0 0 0-3.204 1.641 3.7 3.7 0 0 0-.291 3.59l5.234 11.484c-.509.922-1.012 1.852-1.5 2.796l-12.449 2.025a3.7 3.7 0 0 0-2.407 5.814l7.365 10.23q-.482 1.514-.925 3.047l-11.808 4.415a3.702 3.702 0 0 0-1.225 6.171l9.237 8.614c-.115 1.04-.217 2.087-.305 3.131L1.75 124.862A3.7 3.7 0 0 0 0 128.007c0 1.284.663 2.473 1.751 3.143l10.748 6.653q.132 1.572.305 3.131l-9.238 8.617a3.697 3.697 0 0 0 1.226 6.169l11.808 4.415c.294 1.022.605 2.037.925 3.047l-7.365 10.231a3.696 3.696 0 0 0 2.41 5.812l12.447 2.025c.487.944.986 1.874 1.5 2.8l-5.235 11.48a3.69 3.69 0 0 0 .291 3.59 3.68 3.68 0 0 0 3.204 1.641l12.63-.442c.659.821 1.322 1.626 1.997 2.426l-2.899 12.31a3.68 3.68 0 0 0 .986 3.459 3.68 3.68 0 0 0 3.466.983l12.305-2.898c.8.68 1.61 1.34 2.427 1.99l-.44 12.639a3.694 3.694 0 0 0 5.229 3.492l11.481-5.231a106 106 0 0 0 2.796 1.499l2.03 12.445a3.69 3.69 0 0 0 2.235 2.825 3.7 3.7 0 0 0 3.579-.413l10.229-7.37c1.01.32 2.025.633 3.047.927l4.415 11.804a3.69 3.69 0 0 0 2.744 2.331 3.68 3.68 0 0 0 3.425-1.106l8.617-9.238c1.04.12 2.086.22 3.133.313l6.653 10.748a3.7 3.7 0 0 0 3.143 1.75 3.7 3.7 0 0 0 3.145-1.75l6.653-10.748c1.047-.093 2.092-.193 3.131-.313l8.615 9.238a3.68 3.68 0 0 0 3.424 1.106 3.69 3.69 0 0 0 2.744-2.331l4.415-11.804c1.022-.294 2.038-.607 3.048-.927l10.231 7.37a3.7 3.7 0 0 0 5.812-2.412l2.03-12.445c.939-.487 1.868-.993 2.795-1.5l11.481 5.232a3.692 3.692 0 0 0 5.23-3.492l-.44-12.638a99 99 0 0 0 2.423-1.991l12.306 2.898c1.25.294 2.56-.07 3.463-.983a3.68 3.68 0 0 0 .986-3.459l-2.898-12.31c.675-.8 1.34-1.605 1.99-2.426l12.636.442a3.68 3.68 0 0 0 3.204-1.64 3.69 3.69 0 0 0 .289-3.592l-5.232-11.478c.511-.927 1.013-1.857 1.497-2.8l12.45-2.026a3.68 3.68 0 0 0 2.822-2.236 3.7 3.7 0 0 0-.415-3.576l-7.365-10.23q.479-1.516.925-3.048l11.806-4.415a3.68 3.68 0 0 0 2.331-2.745 3.68 3.68 0 0 0-1.106-3.424l-9.235-8.617c.112-1.04.215-2.086.305-3.13l10.748-6.654a3.69 3.69 0 0 0 1.751-3.143c0-1.281-.66-2.472-1.749-3.145m-71.932 89.156c-4.104-.885-6.714-4.93-5.833-9.047.878-4.112 4.92-6.729 9.023-5.844 4.104.879 6.718 4.931 5.838 9.04-.88 4.11-4.926 6.73-9.028 5.851m-3.652-24.699a6.93 6.93 0 0 0-8.23 5.332l-3.816 17.807c-11.775 5.344-24.85 8.313-38.621 8.313-14.086 0-27.446-3.116-39.43-8.688l-3.814-17.806c-.802-3.747-4.486-6.134-8.228-5.33l-15.72 3.376a93 93 0 0 1-8.128-9.58h76.49c.865 0 1.442-.157 1.442-.945v-27.057c0-.787-.577-.944-1.443-.944H106.8v-17.15h24.195c2.208 0 11.809.63 14.878 12.902.962 3.774 3.072 16.05 4.516 19.98 1.438 4.408 7.293 13.213 13.533 13.213h38.115c.433 0 .895-.049 1.382-.137a94 94 0 0 1-8.669 10.17zm-105.79 24.327c-4.105.886-8.146-1.731-9.029-5.843-.878-4.119 1.732-8.162 5.836-9.047 4.105-.878 8.148 1.739 9.028 5.85.878 4.11-1.734 8.16-5.836 9.04M43.86 95.986c1.703 3.842-.03 8.345-3.867 10.045-3.837 1.705-8.328-.03-10.03-3.875-1.703-3.845.029-8.34 3.867-10.045a7.6 7.6 0 0 1 10.03 3.874m-8.918 21.14 16.376-7.277a6.94 6.94 0 0 0 3.524-9.158l-3.372-7.626h13.264v59.788H37.973a93.7 93.7 0 0 1-3.566-25.672c0-3.398.183-6.756.535-10.056m71.862-5.807V93.696h31.586c1.632 0 11.52 1.886 11.52 9.28 0 6.139-7.584 8.34-13.821 8.34h-29.285zm114.792 15.862q0 3.506-.257 6.948h-9.603c-.961 0-1.348.632-1.348 1.573v4.41c0 10.38-5.853 12.638-10.982 13.213-4.884.55-10.3-2.045-10.967-5.034-2.882-16.206-7.683-19.667-15.265-25.648 9.41-5.975 19.2-14.79 19.2-26.59 0-12.74-8.734-20.765-14.688-24.7-8.352-5.506-17.6-6.61-20.095-6.61H58.279c13.467-15.03 31.719-25.677 52.362-29.551l11.706 12.28a6.923 6.923 0 0 0 9.799.226l13.098-12.528c27.445 5.11 50.682 22.194 64.073 45.633l-8.967 20.253c-1.548 3.505.032 7.604 3.527 9.157l17.264 7.668c.298 3.065.455 6.161.455 9.3M122.352 24.745c3.033-2.905 7.844-2.79 10.748.247 2.898 3.046 2.788 7.862-.252 10.765-3.033 2.906-7.844 2.793-10.748-.25a7.62 7.62 0 0 1 .252-10.762m88.983 71.61a7.594 7.594 0 0 1 10.028-3.872c3.838 1.702 5.57 6.203 3.867 10.045a7.595 7.595 0 0 1-10.03 3.875c-3.833-1.703-5.565-6.2-3.865-10.048",
        ),
      ]),
    ],
  )
}

pub fn sac() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 120 120"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute.attribute(
          "transform",
          "matrix(1.06223 0 0 .94142 3.522 -5.544)",
        ),
        attribute.attribute(
          "style",
          "font-weight:700;font-stretch:semi-condensed;font-size:117.604px;line-height:100%;font-family:\"NotoSans Nerd Font Mono\";-inkscape-font-specification:\"NotoSans Nerd Font Mono, Bold Semi-Condensed\";letter-spacing:0;word-spacing:0;stroke-width:2.94009px",
        ),
        attribute.attribute("aria-label", "C"),
        attribute.attribute(
          "d",
          "M40.215 36.816q-11.643 0-19.758 5.528-7.997 5.527-12.23 15.289-4.117 9.76-4.116 22.46 0 13.173 3.881 22.934 3.88 9.645 11.643 14.936 7.761 5.176 19.404 5.176 11.407 0 20.7-4.235v-14.7q-5.059 1.999-9.645 3.292a36 36 0 0 1-9.174 1.176q-9.76 0-14.465-7.408-4.586-7.41-4.586-21.051 0-13.054 4.703-20.934 4.823-7.997 13.996-7.998 4.234 0 8.467 1.53a48 48 0 0 1 8.233 3.646l5.41-13.996q-10.938-5.645-22.463-5.645",
        ),
      ]),
      svg.path([
        attribute.attribute("transform", "translate(3.522 -5.544)"),
        attribute.attribute(
          "style",
          "font-weight:600;font-size:73.8305px;line-height:100%;font-family:\"NotoSans Nerd Font Mono\";-inkscape-font-specification:\"NotoSans Nerd Font Mono, Semi-Bold\";letter-spacing:0;word-spacing:0;fill:#ffc02e;stroke-width:1.84577px",
        ),
        attribute.attribute("aria-label", "λ"),
        attribute.attribute(
          "d",
          "M74.996 15.164q-1.329 0-2.953.22-1.55.149-2.584.37v7.605q.739-.147 1.7-.295a15 15 0 0 1 2.14-.148q2.953 0 4.578 1.328 1.697 1.33 3.1 4.947l1.55 4.135L65.473 71.72h9.597l8.047-18.754a46 46 0 0 0 1.774-4.65q.885-2.585 1.476-4.727h.295q.368 1.772 1.254 4.504.887 2.657 1.773 5.168l4.207 11.812q1.257 3.545 3.25 5.465 2.068 1.92 5.907 1.92 1.403 0 3.027-.297 1.697-.296 2.51-.738v-7.088q-1.256.37-2.363.37-1.477 0-2.659-1.18-1.18-1.256-2.51-4.874L89.91 27.863q-1.476-4.134-3.322-6.941-1.772-2.88-4.504-4.281-2.732-1.477-7.088-1.477",
        ),
      ]),
    ],
  )
}

pub fn scala() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "-50 -70 352 572"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.defs([], [
        svg.linear_gradient(
          [
            attribute.attribute("y2", "50%"),
            attribute.attribute("y1", "50%"),
            attribute.attribute("x2", "100%"),
            attribute.attribute("x1", "0%"),
            attribute.id("scalaGradient1"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#4F4F4F"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([attribute.attribute("offset", "100%")]),
          ],
        ),
        svg.linear_gradient(
          [
            attribute.attribute("y2", "50%"),
            attribute.attribute("y1", "50%"),
            attribute.attribute("x2", "100%"),
            attribute.attribute("x1", "0%"),
            attribute.id("scalaGradient2"),
          ],
          [
            svg.stop([
              attribute.attribute("stop-color", "#C40000"),
              attribute.attribute("offset", "0%"),
            ]),
            svg.stop([
              attribute.attribute("stop-color", "red"),
              attribute.attribute("offset", "100%"),
            ]),
          ],
        ),
      ]),
      svg.path([
        attribute.attribute("transform", "matrix(1 0 0 -1 0 544)"),
        attribute.attribute(
          "d",
          "M0 288v-32c0-5.394 116.377-14.428 192.2-32 36.628 8.49 63.8 18.969 63.8 32v32c0 13.024-27.172 23.51-63.8 32C116.376 302.425 0 293.39 0 288",
        ),
        attribute.attribute("fill", "url(#scalaGradient1)"),
      ]),
      svg.path([
        attribute.attribute("transform", "matrix(1 0 0 -1 0 288)"),
        attribute.attribute(
          "d",
          "M0 160v-32c0-5.394 116.377-14.428 192.2-32 36.628 8.49 63.8 18.969 63.8 32v32c0 13.024-27.172 23.51-63.8 32C116.376 174.425 0 165.39 0 160",
        ),
        attribute.attribute("fill", "url(#scalaGradient1)"),
      ]),
      svg.path([
        attribute.attribute("transform", "matrix(1 0 0 -1 0 416)"),
        attribute.attribute(
          "d",
          "M0 224v-96c0 8 256 24 256 64v96c0-40-256-56-256-64",
        ),
        attribute.attribute("fill", "url(#scalaGradient2)"),
      ]),
      svg.path([
        attribute.attribute("transform", "matrix(1 0 0 -1 0 160)"),
        attribute.attribute(
          "d",
          "M0 96V0c0 8 256 24 256 64v96c0-40-256-56-256-64",
        ),
        attribute.attribute("fill", "url(#scalaGradient2)"),
      ]),
      svg.path([
        attribute.attribute("transform", "matrix(1 0 0 -1 0 672)"),
        attribute.attribute(
          "d",
          "M0 352v-96c0 8 256 24 256 64v96c0-40-256-56-256-64",
        ),
        attribute.attribute("fill", "url(#scalaGradient2)"),
      ]),
    ],
  )
}

pub fn swift() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("preserveAspectRatio", "xMidYMid"),
      attribute.attribute("viewBox", "0 0 256 256"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.linear_gradient(
        [
          attribute.attribute("gradientUnits", "userSpaceOnUse"),
          attribute.attribute(
            "gradientTransform",
            "rotate(180 -846.605 623.252)",
          ),
          attribute.attribute("y2", "981.338"),
          attribute.attribute("y1", "1255.639"),
          attribute.attribute("x2", "-1797.134"),
          attribute.attribute("x1", "-1845.501"),
          attribute.id("swiftGradient1"),
        ],
        [
          svg.stop([
            attribute.attribute("style", "stop-color:#faae42"),
            attribute.attribute("offset", "0"),
          ]),
          svg.stop([
            attribute.attribute("style", "stop-color:#ef3e31"),
            attribute.attribute("offset", "1"),
          ]),
        ],
      ),
      svg.path([
        attribute.attribute(
          "d",
          "M56.9 0h141.8c6.9 0 13.6 1.1 20.1 3.4 9.4 3.4 17.9 9.4 24.3 17.2 6.5 7.8 10.8 17.4 12.3 27.4.6 3.7.7 7.4.7 11.1v138.3c0 4.4-.2 8.9-1.1 13.2-2 9.9-6.7 19.2-13.5 26.7-6.7 7.5-15.5 13.1-25 16.1-5.8 1.8-11.8 2.6-17.9 2.6-2.7 0-142.1 0-144.2-.1-10.2-.5-20.3-3.8-28.8-9.5-8.3-5.6-15.1-13.4-19.5-22.4-3.8-7.7-5.7-16.3-5.7-24.9V56.9C.2 48.4 2 40 5.7 32.4c4.3-9 11-16.9 19.3-22.5C33.5 4.1 43.5.7 53.7.2c1-.2 2.1-.2 3.2-.2",
        ),
        attribute.attribute("fill", "url(#swiftGradient1)"),
      ]),
      svg.linear_gradient(
        [
          attribute.attribute("gradientUnits", "userSpaceOnUse"),
          attribute.attribute("y2", "204.893"),
          attribute.attribute("y1", "4.136"),
          attribute.attribute("x2", "95.213"),
          attribute.attribute("x1", "130.612"),
          attribute.id("swiftGradient2"),
        ],
        [
          svg.stop([
            attribute.attribute("style", "stop-color:#e39f3a"),
            attribute.attribute("offset", "0"),
          ]),
          svg.stop([
            attribute.attribute("style", "stop-color:#d33929"),
            attribute.attribute("offset", "1"),
          ]),
        ],
      ),
      svg.path([
        attribute.attribute(
          "d",
          "M216 209.4c-.9-1.4-1.9-2.8-3-4.1-2.5-3-5.4-5.6-8.6-7.8-4-2.7-8.7-4.4-13.5-4.6-3.4-.2-6.8.4-10 1.6-3.2 1.1-6.3 2.7-9.3 4.3-3.5 1.8-7 3.6-10.7 5.1-4.4 1.8-9 3.2-13.7 4.2-5.9 1.1-11.9 1.5-17.8 1.4-10.7-.2-21.4-1.8-31.6-4.8-9-2.7-17.6-6.4-25.7-11.1-7.1-4.1-13.7-8.8-19.9-14.1-5.1-4.4-9.8-9.1-14.2-14.1-3-3.5-5.9-7.2-8.6-11-1.1-1.5-2.1-3.1-3-4.7L0 121.2V56.7C0 25.4 25.3 0 56.6 0h50.5l37.4 38c84.4 57.4 57.1 120.7 57.1 120.7s24 27 14.4 50.7",
        ),
        attribute.attribute("fill", "url(#swiftGradient2)"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M144.7 38c84.4 57.4 57.1 120.7 57.1 120.7s24 27.1 14.3 50.8c0 0-9.9-16.6-26.5-16.6-16 0-25.4 16.6-57.6 16.6-71.7 0-105.6-59.9-105.6-59.9C91 192.1 135.1 162 135.1 162c-29.1-16.9-91-97.7-91-97.7 53.9 45.9 77.2 58 77.2 58-13.9-11.5-52.9-67.7-52.9-67.7 31.2 31.6 93.2 75.7 93.2 75.7C179.2 81.5 144.7 38 144.7 38",
        ),
        attribute.attribute("fill", "#FFF"),
      ]),
    ],
  )
}

pub fn typescript() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 256 256"),
      attribute.attribute("version", "1"),
      attribute.attribute("fill", "#007ACC"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.rect([
        attribute.attribute("fill", "#fff"),
        attribute.attribute("height", "100%"),
        attribute.attribute("width", "100%"),
      ]),
      svg.path([
        attribute.attribute(
          "d",
          "M0 128v128h256V0H0zm157-4.5V135h-33v105H97V135H64v-23h93zm65-10.1c4.1.8 8.7 1.9 10.3 2.5l2.7 1.1v12.5c0 6.9-.2 12.5-.4 12.5s-2.3-1.1-4.7-2.4c-9-5.1-23.4-7-32.2-4.4-2.1.6-5.2 2.5-6.8 4.1-2.4 2.3-2.9 3.7-2.9 7.4 0 4 .5 5.1 3.8 8.2 2.1 2 9.9 6.6 17.5 10.4 16 7.9 24.1 14.6 27.8 22.9 3.3 7.4 3.4 23 .2 30-3 6.6-9.6 13.3-16.1 16.4-13.8 6.5-36.3 7.1-53.9 1.3l-6.3-2.1V206l5 3.6c6.5 4.7 14.9 7.6 23.7 8.2s15.3-1 19.3-4.8c2.5-2.3 3-3.6 3-7.4 0-7.3-4.2-11.1-21.4-19.5-15.2-7.5-20-10.9-24.5-17.5-10-14.5-7-36.7 6.4-46.8 11.4-8.7 30.3-11.9 49.5-8.4",
        ),
      ]),
    ],
  )
}

pub fn zig() -> element.Element(msg) {
  svg.svg(
    [
      attribute.attribute("viewBox", "0 0 154 140"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.g([attribute.attribute("fill", "#F7A41D")], [
        svg.path([attribute.attribute("d", "M46 22 28 44l-9-14z")]),
        svg.path([
          attribute.attribute("shape-rendering", "crispEdges"),
          attribute.attribute(
            "d",
            "M46 22 33 33l-5 11h-6v51h9l-11 5-8 17H0V22z",
          ),
        ]),
        svg.path([
          attribute.attribute("d", "m31 95-19 22-8-11zM56 22l6 14-25 8z"),
        ]),
        svg.path([
          attribute.attribute("shape-rendering", "crispEdges"),
          attribute.attribute("d", "M56 22h55v22H37l19-12z"),
        ]),
        svg.path([attribute.attribute("d", "m116 95-19 22-7-13z")]),
        svg.path([
          attribute.attribute("shape-rendering", "crispEdges"),
          attribute.attribute("d", "m116 95-16 9-3 13H42V95z"),
        ]),
        svg.path([
          attribute.attribute(
            "d",
            "M150 0 52 117 3 140l98-118zM141 22l-1 18-18 5z",
          ),
        ]),
        svg.path([
          attribute.attribute("shape-rendering", "crispEdges"),
          attribute.attribute(
            "d",
            "M153 22v95h-47l14-12 5-10h6V45h-9l10-9 9-14z",
          ),
        ]),
        svg.path([attribute.attribute("d", "m125 95 5 15-24 7z")]),
      ]),
    ],
  )
}
