// Модуль умножения двух целых чисел заданной длины
// Модуль принимает данные по шинам A и B по переднему фронту CLK в том случае, если
// на текущем такте CLK сигнал ENA активный, а на предыдущем был пассивным.
// Сигнал ACCEPTED устанавливается на следующем такте CLK после приема данных на обработку.
// После появления сигнала ACCEPTED сигналы ENA, A и B можно снимать.
// Сигнал DONE появляется одновременно с появлением на шине OUT результатов вычислений
// (т.е. на следующем такте CLK данные на OUT точно валидны).
// Сигнал COMPLETE появляется через один такт CLK после сигнала DONE (и появления данных на
// шине OUT). 
module MUL(clk, ena, a, b, accepted, done, complete, out);
parameter WIDTH_A=8;			 
parameter WIDTH_B=8;			 
localparam WIDTH_OUT=WIDTH_A+WIDTH_B;

input logic clk;
// Сигнал разрешения работы
input logic ena;
// Множитель
input logic [WIDTH_A-1:0] a;
// Множитель
input logic [WIDTH_B-1:0] b;
// Сигнал, подтверждающий прием данных на обработку
output logic accepted;
// Предварительный признак завершения вычислений
output logic done;
// Признак завершения вычислений
output logic complete;
// Результат
output logic [WIDTH_OUT-1:0] out;

// Выполняем задержку сигнала ena на 1 такт
always @(posedge clk) begin
	accepted <= ena;
end

// Сдвигаемое значение 1-го множителя
logic [$left(out)-1:0] pending_a;

// Оставшееся значение 2-го множителя
logic [$left(b)-1:0] pending_b;

// Признак нулевого значения операнда A
logic zero_a;

// Формирование сигнала done
always @(*) begin
	done = zero_a | (~|pending_b);
end

// Выполнение основного функционала
always @(posedge clk) begin
	if(ena & (accepted ^ ena)) begin
		// Сигнал ena только что перешел из пассивного в активное состояние
		
			// Начальное значение результата по младшему биту множителя b
			if(b[$right(b)]) begin
				// Сразу выполняем первую операцию сложения
				out <= { { ($size(out)-$size(a)){1'b0} }, a };
			end else begin
				// Младший бит нулевой, поэтому значение нулевое
				out <= 'b0;
			end
		
			// Проверяем операнд A на нулевое значение
			zero_a <= ~|a;
		
			// Первый "сдвиг" 1-го множителя влево на 1 разряд
			pending_a <= { { ($size(pending_a)-$size(a)){1'b0} }, a };
			
		
			// Первый "сдвиг" 2-го множителя вправо на 1 разряд
			pending_b <= b[$left(b):$right(b)+1];
	end else begin
		// Выполнение вычислений, пока они имеют смысл
		if(~done) begin
			// Вычисления еще не завершены
			if(pending_b[$right(pending_b)]) begin
				// Требуется выполнить сложение и сдвиг. Т.к. первое "сложение" было выполнено в первом такте,
				// то мы можем сэкономить 1 сумматор.
				// Поэтому вместо строчки "out <= out + { pending_a, 1'b0 };" пишем
				out[$left(out):$right(out)+1] <= out[$left(out):$right(out)+1] + pending_a;
			end
			
			// Операнд A сдвигается влево (умножаем на 2)
			pending_a <= { pending_a[$left(pending_a)-1:$right(pending_a)], 1'b0 };
			
			// Операнд B сдвигается вправо (делим на 2)
			pending_b <= { 1'b0, pending_b[$left(pending_b):$right(pending_b)+1] };
		end
	end
end

// Формирование сигнала complete
always @(posedge clk) begin
	complete <= done;
end

			 
endmodule

`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 10 ps						 

// Тестирование						 
module MUL_testbench;
	// Период тактового сигнала
	localparam half_period=10;
	localparam period=half_period*2;
	
	localparam WIDTH_A=4;
	localparam WIDTH_B=4;
	localparam WIDTH_OUT=WIDTH_A+WIDTH_B;

	logic rst;
	logic clk;
	logic ena;
	logic [WIDTH_A-1:0] a;
	logic [WIDTH_B-1:0] b;
	logic accepted;
	logic done;
	logic complete;
	logic [WIDTH_OUT-1:0] out;
	
	MUL #(.WIDTH_A(WIDTH_A), .WIDTH_B(WIDTH_B))
	    mul(.clk(clk),
			  .ena(ena),
			  .a(a),
			  .b(b),
			  .accepted(accepted),
			  .done(done),
			  .complete(complete),
			  .out(out)
			 );
	
	// Инициализация значений
	initial begin 
		rst = 1;
		clk = 0;
		ena = 0;
//		a = 0;
//		b = 0;
	end
	
	// Генерация тактового сигнала
	always begin
		#(half_period);
		clk = ~clk;
	end
	
	// Генерация данных для проверки
	always @(posedge clk) begin
		if(ena) begin
			// Процесс вычислений был начат
			ena = 0;
		end else begin
			if(rst) begin
				// Первое вычисление также выполняет функцию сброса при симуляции
				ena = 1;
				
				// Начальное значение множителей
				a = 0;
				b = 0;
				
				// Снимаем сигнал сброса
				rst = 0;
			end else begin
				// Сброс был произведен ранее, рабочий цикл
				if(done) begin
					// Начинаем процесс вычислений
					ena = 1;
				
					a = a + 1;
					if(0 == a) begin
						b = b + 1;
					
						if(0 == b) begin
							$display("Successfully testbench complete at %d ",$time);
						
							//$exit;
							$stop;
							// $finish
						end
					end
				end
			end
		end
	end
	
	// Проверка результата работы блока
	always @(negedge clk) begin
		if(done & ~ena) begin
			// Вычисление завершено
			assert (out == (a * b));
		end
	end
endmodule
			 