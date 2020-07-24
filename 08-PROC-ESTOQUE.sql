-- CRIANDO PROCEDURE PARA ALIMENTAR ESTOQUE
--REGRAS
/*
VERIFICAR SE A OPERACAO E PERMITIDA (-E ENTRADA E S SAIDA
VERIFICAR SE O MATERIAL EXISTE
-- VERIFICOES DE SAIDA
1 VERIFICAR SE MATERIAL TEM SALDO ESTOQUE E E QTD SAIDA E MENOR QUE SALDO
2 VERIFICAR SE MATERIAL TEM SALDO ESTOQUE_LOTE E E QTD SAIDA E MENOR QUE SALDO DO LOTE
-- VERIFICACOES ENTRADA
1 SE MATERIAL EXISTE UPDATE
2 SENAO EXISTE INSERT
TABELAS ENVOLVIDAS
ESTOQUE
ESTOQUE_LOTE
ESTQUE_MOV
-- EXECOES ROLLBACK


*/
CREATE OR REPLACE PROCEDURE PRC_MOV_ESTOQUE (P_OPER IN VARCHAR2,
                                             P_EMP IN NUMBER,
                                             P_COD_MAT IN INT,
                                             P_LOTE IN VARCHAR2,
                                             P_QTD IN INT,
                                             P_DATA_MOV DATE)
IS

    EXC_MAT_N_EXISTE EXCEPTION;
    EXC_OPERACAO_NAO_PERMITIDA EXCEPTION;
    EXC_ESTOQUE_NEGATIVO EXCEPTION;
    EXC_ESTOQUE_NEGATIVO_LOTE EXCEPTION;
    
    V_SALDO_ESTOQUE INT;
    V_SALDO_ESTOQUE_LOTE INT;
    V_MAT_EXISTE INT ;
    V_REG_ESTOQUE INT;
    V_REG_ESTOQUE_LOTE INT;


BEGIN 
    -- VERIFICANDO SE OPERACAO � PERMITIDA;
    IF P_OPER NOT IN ('E','S') THEN
        RAISE EXC_OPERACAO_NAO_PERMITIDA;
    ELSE 
    dbms_output.put_line('OPERACAO OK! CONTINUA!');
    END IF;
    -- VERIFICANDO SE MATERIAL EXISTE
    SELECT COUNT(*) INTO V_MAT_EXISTE FROM MATERIAL WHERE COD_MAT=P_COD_MAT AND COD_EMPRESA=P_EMP;
    
    IF V_MAT_EXISTE=0 THEN
        RAISE EXC_MAT_N_EXISTE;
    ELSE
        dbms_output.put_line('MATERIAL EXISTE! CONTINUA');
    END IF;
  
  --VERIFICANDO SE EXISTE REGISTRO EM ESTOQUE
  SELECT COUNT(*) INTO V_REG_ESTOQUE 
  FROM ESTOQUE 
  WHERE COD_MAT=P_COD_MAT AND COD_EMPRESA=P_EMP;
  
   dbms_output.put_line('QTD REG ESTOQUE '||V_REG_ESTOQUE);
  -- VERIFICANDO OPERACAO DE SAIDA SE MATERIAL EXISTE NAO ESTOQUE
  IF P_OPER='S' AND V_REG_ESTOQUE=0 
  THEN
      RAISE EXC_ESTOQUE_NEGATIVO;
      ELSIF  P_OPER='S' AND V_REG_ESTOQUE>0  THEN
       -- ATRIBUINDO SALDO DE ESTOQUE E QTD REGISTRO
        SELECT QTD_SALDO,COUNT(*) INTO V_SALDO_ESTOQUE,V_REG_ESTOQUE FROM ESTOQUE 
        WHERE COD_MAT=P_COD_MAT AND COD_EMPRESA=P_EMP
        GROUP BY QTD_SALDO;
        dbms_output.put_line('TEM ESTOQUE');
  END IF;
  
  --VERIFICANDO SE EXISTE REGISTRO EM ESTOQUE LOTE
  SELECT COUNT(*) INTO V_REG_ESTOQUE_LOTE 
  FROM ESTOQUE_LOTE 
  WHERE COD_MAT=P_COD_MAT AND LOTE=P_LOTE AND COD_EMPRESA=P_EMP;
  dbms_output.put_line('QTD REG ESTOQUE LOTE '||V_REG_ESTOQUE_LOTE);
  -- VERIFICANDO OPERACAO DE SAIDA SE MATERIAL EXISTE NAO ESTOQUE
  IF P_OPER='S' AND V_REG_ESTOQUE_LOTE=0 
  THEN
      RAISE EXC_ESTOQUE_NEGATIVO_LOTE;
      ELSIF P_OPER='S' AND V_REG_ESTOQUE_LOTE>0 THEN
      -- ATRIBUINDO SALDO DE ESTOQUE_LOTE E QTD REGISTRO
        SELECT SUM(QTD_LOTE),COUNT(*) INTO V_SALDO_ESTOQUE_LOTE,V_REG_ESTOQUE_LOTE FROM ESTOQUE_LOTE 
        WHERE COD_MAT=P_COD_MAT AND LOTE=P_LOTE AND COD_EMPRESA=P_EMP;
        dbms_output.put_line('TEM ESTOQUE LOTE');
  END IF;
  
  IF P_OPER='S' AND  (V_SALDO_ESTOQUE_LOTE-P_QTD<0 OR V_SALDO_ESTOQUE-P_QTD<0) THEN
     RAISE EXC_ESTOQUE_NEGATIVO_LOTE;
    ELSIF P_OPER='S' AND  V_SALDO_ESTOQUE_LOTE-P_QTD>=0 AND V_SALDO_ESTOQUE-P_QTD>=0 THEN
    -- ATUALIZA ESTOQUE
    UPDATE ESTOQUE SET QTD_SALDO=QTD_SALDO-P_QTD WHERE COD_MAT=P_COD_MAT AND COD_EMPRESA=P_EMP;
    -- ATUALIZA ESTOQUE LOTE
    UPDATE ESTOQUE_LOTE SET QTD_LOTE=QTD_LOTE-P_QTD WHERE COD_MAT=P_COD_MAT AND LOTE=P_LOTE AND COD_EMPRESA=P_EMP;
    -- INSERE ESTOQUE TIP_MOV
    INSERT INTO ESTOQUE_MOV (id_mov,cod_empresa,tip_mov,cod_mat,lote,qtd,login,data_hora,DATA_MOV) VALUES
        (nULL,P_EMP,P_OPER,P_COD_MAT,P_LOTE,P_QTD,USER,SYSDATE,P_DATA_MOV);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OPERACAO FINALIZADA');
    END IF;
    -- FINALIZA OPERACAO PARA SAIDA
    --INICIA OPERACAO PARA ENTRADA
    
    --VERIFCANDO SE MATERIAL TEM REGISTRO NA ESTOQUE E ESTOQUE LOTE
    IF P_OPER='E' AND V_REG_ESTOQUE_LOTE>0 AND V_REG_ESTOQUE>0 THEN
        -- ATUALIZANDO ESTOQUE
         UPDATE ESTOQUE SET QTD_SALDO=QTD_SALDO+P_QTD WHERE COD_MAT=P_COD_MAT AND COD_EMPRESA=P_EMP;
          -- ATUALIZANDO ESTOQUE_LOTE
         UPDATE ESTOQUE_LOTE SET QTD_LOTE=QTD_LOTE+P_QTD WHERE COD_MAT=P_COD_MAT AND LOTE=P_LOTE AND COD_EMPRESA=P_EMP;
         -- INSERE ESTOQUE TIP_MOV
         INSERT INTO ESTOQUE_MOV (id_mov,COD_EMPRESA,tip_mov,cod_mat,lote,qtd,login,data_hora,DATA_MOV) VALUES
            (nULL,P_EMP,P_OPER,P_COD_MAT,P_LOTE,P_QTD,USER,SYSDATE,P_DATA_MOV);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('OPERACAO FINALIZADA');
        -- VERIFICA QUE EXISTE ESTOQUE MAS NAO EXISTE ESTOQUE LOTE PARA INSERT ESTOQUE LOTE E UPDATE ESTOQUE
    ELSIF P_OPER='E' AND V_REG_ESTOQUE_LOTE=0 AND V_REG_ESTOQUE>0 THEN
        -- ATUALIZANDO ESTOQUE
         UPDATE ESTOQUE SET QTD_SALDO=QTD_SALDO+P_QTD WHERE COD_MAT=P_COD_MAT AND COD_EMPRESA=P_EMP;
        --INSERINDO REGISTRO NA ESTOQUE LOTE
         INSERT INTO ESTOQUE_LOTE (COD_EMPRESA,COD_MAT,QTD_LOTE,LOTE) VALUES (P_EMP,P_COD_MAT,P_QTD,P_LOTE);
          -- INSERE ESTOQUE TIP_MOV
         INSERT INTO ESTOQUE_MOV (id_mov,COD_EMPRESA,tip_mov,cod_mat,lote,qtd,login,data_hora,DATA_MOV) VALUES
            (nULL,P_EMP,P_OPER,P_COD_MAT,P_LOTE,P_QTD,USER,SYSDATE,P_DATA_MOV);
         COMMIT;
        DBMS_OUTPUT.PUT_LINE('OPERACAO FINALIZADA');
        -- VERIFICANDO QUE NAO EXISTE ESTOQUE E ESTOQUE LOTE PARA INSERT
    ELSIF P_OPER='E' AND V_REG_ESTOQUE_LOTE=0 AND V_REG_ESTOQUE=0 THEN
        -- INSERINDO ESTOQUE
         INSERT INTO  ESTOQUE (COD_EMPRESA,COD_MAT,QTD_SALDO) VALUES (P_EMP,P_COD_MAT,P_QTD);
        --INSERINDO REGISTRO NA ESTOQUE LOTE
         INSERT INTO ESTOQUE_LOTE (COD_EMPRESA,COD_MAT,QTD_LOTE,LOTE) VALUES (P_EMP,P_COD_MAT,P_QTD,P_LOTE);
          -- INSERE ESTOQUE TIP_MOV
         INSERT INTO ESTOQUE_MOV (id_mov,COD_EMPRESA,tip_mov,cod_mat,lote,qtd,login,data_hora,DATA_MOV) VALUES
            (nULL,P_EMP,P_OPER,P_COD_MAT,P_LOTE,P_QTD,USER,SYSDATE,P_DATA_MOV);
         COMMIT;
        DBMS_OUTPUT.PUT_LINE('OPERACAO FINALIZADA');
    END IF;
    -- TERMINA ENTRADA
    --INICIA EXCESSOES
EXCEPTION
    when EXC_OPERACAO_NAO_PERMITIDA THEN
        DBMS_OUTPUT.PUT_LINE('A OPERACAO DEVER SER E-ENTRADA OU S-SAIDA');
        ROLLBACK;
     
     when EXC_MAT_N_EXISTE THEN
        DBMS_OUTPUT.PUT_LINE('MATERIAL NAO EXISTE CADASTRO');
        ROLLBACK;
     
    when EXC_ESTOQUE_NEGATIVO THEN
        DBMS_OUTPUT.PUT_LINE('ESTOQUE NEGATIVO,OPERACAO NAO PERMITIDA!!!');
        ROLLBACK;
     
    when EXC_ESTOQUE_NEGATIVO_LOTE THEN
        DBMS_OUTPUT.PUT_LINE('ESTOQUE LOTE NEGATIVO,OPERACAO NAO PERMITIDA!!!');
        ROLLBACK;
    
    when NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('REGISTRO NAO ENCONTRADO!');
        DBMS_OUTPUT.PUT_LINE('Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
         
     WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('CODIGO DO ERRO '||SQLCODE||' MSG '||SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;

end;

-- testando procedure
--PARAMETROS OPERACAO,COD_EMPRESA,MATERIAL,LOTE,QTD
execute PRC_MOV_ESTOQUE ('S',1,1,'ABC',10,'01/01/2018');


      
select * from ESTOQUE;
SELECT * FROM ESTOQUE_LOTE;
SELECT a.*,to_char(a.DATA_HORA,'dd/mm/yyyy hh24:mi:ss') data 
FROM ESTOQUE_MOV a;
/*
DELETE from ESTOQUE;
DELETE FROM ESTOQUE_LOTE;
DELETE FROM ESTOQUE_MOV;
*/


select to_char(DATA_HORA,'cc dd/mm/yyyy hh24:mi:ss') data from ESTOQUE_MOV;
select to_char(sysdate,'cc dd/mm/yyyy hh24:mi:ss') data from dual;

select to_char(sysdate,'cc dd/mm/yyyy hh24:mi:ss'),
       to_char(current_date,'cc dd/mm/yyyy hh24:mi:ss'),
       sysdate,
       current_date from dual;